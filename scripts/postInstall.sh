#set env vars
set -o allexport; source .env; set +o allexport;

#wait until the server is ready
echo "Waiting for software to be ready ..."
sleep 30s;


if [ -e "./initialized" ]; then
    echo "Already initialized, skipping..."
else

  # URL to access
  URL="https://${DOMAIN}/api/trpc/public.registrationAllowed,public.getWelcomeMessage?batch=1&input=%7B%220%22%3A%7B%22json%22%3Anull%2C%22meta%22%3A%7B%22values%22%3A%5B%22undefined%22%5D%7D%7D%2C%221%22%3A%7B%22json%22%3Anull%2C%22meta%22%3A%7B%22values%22%3A%5B%22undefined%22%5D%7D%7D%7D'"

  COOKIE_FILE=$(mktemp)

  curl -s -c "$COOKIE_FILE" "$URL"

  CSRF_TOKEN=$(grep '__Host-next-auth.csrf-token' "$COOKIE_FILE" | awk '{print $7}')
  AUTH_CALLBACK=$(grep '__Secure-next-auth.callback-url' "$COOKIE_FILE" | awk '{print $7}')

  rm -f "$COOKIE_FILE"

  curl 'https://'${DOMAIN}'/api/trpc/auth.register?batch=1' \
    -H 'accept: */*' \
    -H 'accept-language: fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7,he;q=0.6,zh-CN;q=0.5,zh;q=0.4,ja;q=0.3' \
    -H 'cache-control: no-cache' \
    -H 'content-type: application/json' \
    -H 'cookie: __Host-next-auth.csrf-token='$CSRF_TOKEN'; __Secure-next-auth.callback-url='$AUTH_CALLBACK'' \
    -H 'pragma: no-cache' \
    -H 'priority: u=1, i' \
    -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36' \
    --data-raw '{"0":{"json":{"email":"'${ADMIN_EMAIL}'","password":"'${ADMIN_PASSWORD}'","name":"admin","ztnetInvitationCode":"","token":null},"meta":{"values":{"token":["undefined"]}}}}'



  docker-compose exec -T postgres psql -U postgres -d ztnet -c "UPDATE \"GlobalOptions\" SET \"smtpEmail\" = '${MAIL_SENDER}', \"smtpHost\" = '${MAIL_HOST}', \"smtpPort\" = '${MAIL_PORT}' WHERE id = '1';"
    
  touch "./initialized"
fi