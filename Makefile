VERSION?=latest
OPENSIFT_NAMESPACE?=vmp-quiz

.PHONY: get-resources
get-resources:
	./generate-yamls-from-html.sh "http://www.spspraha.cz/zkousky/otazky.asp?zp=M%202015"
	./generate-yamls-from-html.sh "http://www.spspraha.cz/zkousky/otazky.asp?zp=C"

.PHONY: setup-nvm
setup-nvm:
	npm install

.PHONY: build-image
build-image:
	podman build -t quay.io/pmacik/vmp-quiz:$(VERSION) .

.PHONY: push-image
push-image:
	podman push quay.io/pmacik/vmp-quiz:$(VERSION)

.PHONY: clean
clean:
	rm -rvf node_modules *.html *.txt quizzes/*.yaml
	for i in $$(find public/images -mindepth 1 -type d); do rm -rvf $$i; done

.PHONY: run
run:
	podman run -it --rm -p 8888:8888 quay.io/pmacik/vmp-quiz:$(VERSION)

.PHONY: publish-image
publish-image: push-image
	podman tag quay.io/pmacik/vmp-quiz:$(VERSION) quay.io/pmacik/vmp-quiz:latest
	podman push quay.io/pmacik/vmp-quiz:latest

.PHONY: deploy
deploy:
	kubectl create namespace "${OPENSIFT_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
	kubectl -n $(OPENSIFT_NAMESPACE) apply -f deployment.yaml
	kubectl wait pods -n $(OPENSIFT_NAMESPACE) -l app.kubernetes.io/name=vmp-quiz --for condition=Available --timeout=90s
	@echo 
	@echo "Open https://$$(kubectl -n $(OPENSIFT_NAMESPACE) get routes.route.openshift.io vmp-quiz -o json | jq -rc '.status.ingress[0].host')"

.PHONY: restart
restart:
	kubectl -n $(OPENSIFT_NAMESPACE) rollout restart deployment/vmp-quiz
	kubectl -n $(OPENSIFT_NAMESPACE) wait deployment/vmp-quiz --for condition=Available --timeout=90s

.PHONY: undeploy
undeploy:
	kubectl -n $(OPENSIFT_NAMESPACE) delete -f deployment.yaml --ignore-not-found=true --wait
	kubectl delete namespace $(OPENSIFT_NAMESPACE) --wait
