-module(census_http_sender).
-behaviour(gen_server).
-define(SERVER, ?MODULE).

% TODO(jmink) Determine if there's a already a module/library/something that does
% exactly this except better.

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([start_link/0, send/4]).

%% ------------------------------------------------------------------
%% gen_server Function Exports
%% ------------------------------------------------------------------

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

% @spec start_link() -> {ok,Pid}
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

% @spec send(Port::string(), Port::integer(), Port::string(), Port::array()) -> {}
send(Address, Port, Message, Options) ->
    gen_server:cast(?SERVER, {send, [{address, Address}, {port, Port}, {message, Message},
        {options, Options}]}).             


%% ------------------------------------------------------------------
%% gen_server Function Definitions
%% ------------------------------------------------------------------

init(Args) ->
    {ok, Args}.

handle_call(_Request, _From, State) ->
    io:fwrite("Default call ~n", []),
    {reply, ok, State}.

handle_cast(jmink_test, State) ->
    io:fwrite("jmink_test! ~p ~n", [State]),
    {noreply, State};

% TODO(jmink) Ensure binding matches are of the correct type
% TODO(jmink) It seems silly to have to send port and options everytime
handle_cast({send, [{address, _=Address}, {port, _=Port}, {message, _=Message}, {options, _=Options}]}, State) ->
    io:fwrite("Sending ~p to ~p (Port ~p, Options: ~p) ~n", [Message,Address,Port,Options]),  
    {ok, Sock} = gen_tcp:connect(Address, Port, Options),
    ok = gen_tcp:send(Sock, Message),
    ok = gen_tcp:close(Sock),
    {noreply, State};                     

handle_cast(_Msg, State) ->
    io:fwrite("Default cast ~n", []),
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------


