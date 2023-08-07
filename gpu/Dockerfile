FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu20.04

# Install Python and pip
RUN apt-get update && apt-get install -y python3 python3-dev python3-pip

# Install TensorFlow
RUN pip3 install tensorflow==2.13

# Set the working directory
WORKDIR /tmp

# Set the user to run the container as
USER 1000

# Start the application
CMD ["python3", "-c", "import tensorflow as tf; print(tf.reduce_sum(tf.random.normal([1000, 1000])))"]