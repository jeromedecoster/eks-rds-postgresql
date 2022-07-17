BASTION_PUBLIC_DNS=$(cat $PROJECT_DIR/.env_BASTION_PUBLIC_DNS)
log BASTION_PUBLIC_DNS $BASTION_PUBLIC_DNS

# https://stackoverflow.com/a/19069428
TUNNEL_ID=$(ps aux | grep ssh | grep $BASTION_PUBLIC_DNS | head -n 1 | tr -s ' ' | cut -d ' ' -f 2)
log TUNNEL_ID $TUNNEL_ID

if [[ -n "$TUNNEL_ID" ]];
then
    info kill pid $TUNNEL_ID
    kill -9 $TUNNEL_ID
fi