noblacklist ${HOME}/.tor-browser

mkdir ${HOME}/.tor-browser
whitelist ${HOME}/.tor-browser

# Add tor-browser to private-bin
private-bin bash,cp,dirname,env,expr,file,getconf,gpg,grep,id,ln,mkdir,python*,readlink,rm,sed,sh,tail,tar,tclsh,test,tor-browser-en,torbrowser-launcher,tor-browser,xz,mv

# Redirect
include torbrowser-launcher.profile
