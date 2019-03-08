ENV_FILE := .env
include ${ENV_FILE}
export $(shell sed 's/=.*//' ${ENV_FILE})

# NOTE: the actual commands here have to be indented by TABs
oc_login:
	${OC} login ${OC_URL} -u ${OC_USER} -p ${OC_PASSWORD} --insecure-skip-tls-verify=true

install_knative:
	./knative/install.sh

datagrid: oc_login
	./datagrid/deploy.sh

frontend: oc_login
	./frontend/deploy.sh

kafka:
	./kafka/deploy.sh

ml: oc_login
	./ml/deploy.sh

.PHONY: kafka
