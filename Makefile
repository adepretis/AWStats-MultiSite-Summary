include *.mk

# Define variables, export them and include them usage-documentation
$(eval $(call defw,NAME,awstats-mss))
$(eval $(call defw,PORT,8080))

.PHONY: build
build:: ##@Docker Build an image
	docker build -t $(NAME) .

.PHONY: run
run:: ##@Docker Run a container (build, run attached)
	docker run --rm -p $(PORT):80 --name=$(NAME) $(NAME)
