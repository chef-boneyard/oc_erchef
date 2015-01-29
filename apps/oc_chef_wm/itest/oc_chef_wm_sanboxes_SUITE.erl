%% -*- erlang-indent-level: 4;indent-tabs-mode: nil; fill-column: 92 -*-
%% ex: ts=4 sw=4 et
%% @author Stephen Delano <stephen@opscode.com>
%% Copyright 2013 Opscode, Inc. All Rights Reserved.

-module(oc_chef_wm_sanboxes_SUITE).

-include_lib("common_test/include/ct.hrl").
-include("../../../include/chef_types.hrl").
-include("../../../include/oc_chef_types.hrl").
-include_lib("eunit/include/eunit.hrl").

-record(context, {reqid :: binary(),
                  otto_connection,
                  darklaunch = undefined}).

-compile([export_all, {parse_transform, lager_transform}]).

-define(ORG_AUTHZ_ID, <<"10000000000000000000000000000003">>).
-define(AUTHZ_ID, <<"00000000000000000000000000000004">>).
-define(CLIENT_NAME, <<"test-client">>).
-define(ORG_NAME, <<"org-sanbox-test">>).

-define(CHECKSUMS, [<<"385ea5490c86570c7de71070bce9384a">>,
                    <<"4d5cd68c38a0a5e4078ac247f75e3ab9">>]).

init_per_suite(Config) ->
    Config2 = setup_helper:start_server(Config),

    OrganizationRecord = chef_object:new_record(oc_chef_organization,
                                                nil,
                                                ?ORG_AUTHZ_ID,
                                                {[{<<"name">>, ?ORG_NAME},
                                                  {<<"full_name">>, ?ORG_NAME}]}),
    Result2 = chef_db:create(OrganizationRecord,
                   #context{reqid = <<"fake-req-id">>},
                   ?AUTHZ_ID),
    io:format("Organization Create Result ~p~n", [Result2]),

    % get the OrgId from the database that was generated during Org object creation
    % so we can associate the client with the org.
    {ok, OrgObject} = chef_sql:fetch_object(chef_object:fields_for_fetch(OrganizationRecord),
                                element(1, OrganizationRecord),
                                chef_object:find_query(OrganizationRecord),
                                chef_object:record_fields(OrganizationRecord)
                               ),
    OrgId = OrgObject#oc_chef_organization.id,

    %% create the test client
    ClientRecord = chef_object:new_record(chef_client,
                                          OrgId,
                                          ?AUTHZ_ID,
                                          {[{<<"name">>, ?CLIENT_NAME},
                                            {<<"validator">>, true},
                                            {<<"admin">>, true},
                                            {<<"public_key">>, <<"stub-pub">>}]}),
    io:format("ClientRecord ~p~n", [ClientRecord]),
    Result = chef_db:create(ClientRecord,
                   #context{reqid = <<"fake-req-id">>},
                   ?AUTHZ_ID),

    io:format("Client Create Result ~p~n", [Result]),

    Config2.

end_per_suite(Config) ->
    setup_helper:stop_server(Config).

init_per_testcase(TestName, Config) ->
    %% we don't have bookshelf around, and don't want to pollute
    %% some S3 bucket, so let's mock that part out
    %% and as usual, mocks need to happen in the same thread as the
    %% actual test
    ok = meck:new(chef_s3),
    ok = meck:expect(chef_s3, generate_presigned_url, 5,
                     fun(_, _, _, Checksum, _) ->
                         url_for_checksum(Checksum)
                     end),
    ok = meck:expect(chef_s3, check_checksums, 2,
                     fun(_, Checksums) ->
                         case TestName =:= commit_sandbox_before_uploading of
                             true ->
                                 [First | Others] = ?CHECKSUMS,
                                 {{ok, Others},
                                  {missing, [First]},
                                  {timeout, []},
                                  {error, []}};
                             false ->
                                 {{ok, ?CHECKSUMS},
                                  {missing, []},
                                  {timeout, []},
                                  {error, []}}
                         end
                     end),
    Config.

end_per_testcase(_, Config) ->
    ok = meck:unload(chef_s3),
    Config.

all() ->
    [
        commit_non_existing_sandbox,
        create_sandbox,
        commit_sandbox_before_uploading,
        commit_sandbox
    ].

commit_non_existing_sandbox(_) ->
    NonExistingId = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    ?assertMatch({"404", _},
                 http_commit(NonExistingId)).

create_sandbox(_) ->
    Json = {[{<<"checksums">>,
              {[{C, null} || C <- ?CHECKSUMS ]}}]},
    {RespCode, RespJson} = http_request(post, "", Json),
    ?assertEqual("201", RespCode),
    %% check the body is well formed
    SandboxId = ej:get({<<"sandbox_id">>}, RespJson),
    ExpectedJson = {[{<<"sandbox_id">>, SandboxId},
                     {<<"uri">>, erlang:iolist_to_binary([url_for("/"), SandboxId])},
                     {<<"checksums">>,
                      {[{Checksum,
                         {[{<<"url">>, url_for_checksum(Checksum)},
                           {<<"needs_upload">>, true}]}}
                        || Checksum <- ?CHECKSUMS]}}]},
    ?assertEqual(ExpectedJson, RespJson),

    {save_config, [{sandbox_id, SandboxId}]}.

commit_sandbox_before_uploading(Config) ->
    {create_sandbox, SavedConfig} = ?config(saved_config, Config),
    SandboxId = erlang:binary_to_list(?config(sandbox_id, SavedConfig)),

    ?assertMatch({"503", _},
                 http_commit(SandboxId)),

    {save_config, SavedConfig}.

commit_sandbox(Config) ->
    {commit_sandbox_before_uploading, SavedConfig} = ?config(saved_config, Config),
    SandboxId = erlang:binary_to_list(?config(sandbox_id, SavedConfig)),

    ?assertMatch({"200", _},
                 http_commit(SandboxId)).

http_commit(SandboxId) ->
    http_request(put, "/" ++ SandboxId, {[{<<"is_completed">>, true}]}).

http_request(Method, RouteSuffix, Json) ->
    {ok, RespCode, _, RespBody} = ibrowse:send_req(url_for(RouteSuffix),
                     [{"x-ops-userid", "test-client"},
                      {"accept", "application/json"},
                      {"content-type", "application/json"}],
                     Method, ejson:encode(Json)),
    {RespCode, ejson:decode(RespBody)}.

url_for(RouteSuffix) ->
    OrgNameStr = erlang:binary_to_list(?ORG_NAME),
    "http://localhost:8000/organizations/" ++ OrgNameStr
      ++ "/sandboxes" ++ RouteSuffix.

url_for_checksum(Checksum) ->
    <<"http://fake.url/for/", Checksum/binary>>.