version "0.0.1"
description "A cookbook for managing a Platform-In-A-Box"


# from the default recipe
depends "apt"
depends "build-essential"
depends "git"
depends "yum"

# from the monitoring recipe
depends "estatsd"
depends "graphite"

depends "mysql"
