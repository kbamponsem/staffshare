jwt_secret=$(shell openssl rand -base64 32)

run:
	STAFFSHARE_NEXTAUTH_SECRET=${jwt_secret} \
	docker compose up --build -d

deploy:
	terraform apply -auto-approve -var="staffshare_email_address=${STAFFSHARE_EMAIL_ADDRESS}" \
		-var="staffshare_email_password=${STAFFSHARE_EMAIL_PASSWORD}" \
		-var="staffshare_google_client_id=${STAFFSHARE_GOOGLE_CLIENT_ID}" \
		-var="staffshare_google_client_secret=${STAFFSHARE_GOOGLE_CLIENT_SECRET}" \
		-var="staffshare_jwt_secret=${jwt_secret}"
	
lb-logs:
	docker logs staffshare-loadbalancer -f

api-logs:
	docker logs staffshare-api -f
	
web-logs:
	docker logs staffshare-web -f

destroy-deploy:
	terraform destroy -auto-approve                        

.PHONY: destroy run

all: run