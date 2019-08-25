#!/bin/bash
#
echo "hang tight..checking a couple ting (づ｡◕‿‿◕｡)づ"

. ~/.bashrc
# install/update nvm nodejs npm (stable)
if hash npm 2>/dev/null; then

    echo Now using node@$(node -v) npm@$(npm -v)
else

    echo "(ノಠ益ಠ)ノ彡┻━┻ installing nvm nodejs npm (stable)..."
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.6/install.sh | bash
    . ~/.bashrc
    nvm i stable
fi

echo "(☞ﾟヮﾟ)☞ ☜(ﾟヮﾟ☜) Welcome back! Money T\$am [̲̅\$̲̅(̲̅ ͡° ͜ʖ ͡°̲̅)̲̅\$̲̅]"

