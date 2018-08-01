IMAGE_NAME= strapdata/elassandra

all: publish

build:
	./build.sh 5.5.0.20
	./build.sh 6.2.3.3

publish: 
	docker push "$(IMAGE_NAME):5.5.0.20"
	docker push "$(IMAGE_NAME):6.2.3.3"
