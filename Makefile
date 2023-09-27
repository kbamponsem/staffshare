deploy:
	terraform apply -auto-approve -var="staffshare_email_address=${STAFFSHARE_EMAIL_ADDRESS}" \
		-var="staffshare_email_password=${STAFFSHARE_EMAIL_PASSWORD}" \
		-var="staffshare_google_client_id=${STAFFSHARE_GOOGLE_CLIENT_ID}" \
		-var="staffshare_google_client_secret=${STAFFSHARE_GOOGLE_CLIENT_SECRET}" \
	
lb-logs:
	docker logs staffshare-loadbalancer -f

bk-logs:
	docker logs staffshare-backend -f

destroy:
	terraform destroy -auto-approve

.PHONY: destroy

all: deploy