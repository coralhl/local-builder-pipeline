#!/bin/bash
user_name="coralhl"
image_name="test-image"
versioning_file="VERSION"

# Build image, push to registry / Сборка образа, загрузка в регистр
if ! [ -f $versioning_file ]; then
  echo "Let's buld & push image with tag *latest*"
  docker build --progress=plain -f Dockerfile -t $user_name/$image_name:latest .
  docker push $user_name/$image_name:latest
else
  tag_name=$(cat "$versioning_file")
  echo "Let's buld & push image with tags *latest*, *$tag_name*"
  docker build --progress=plain -f Dockerfile -t $user_name/$image_name:$tag_name -t $user_name/$image_name:latest .
  docker push $user_name/$image_name:$tag_name
  docker push $user_name/$image_name:latest
fi
