VERSION?=latest

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