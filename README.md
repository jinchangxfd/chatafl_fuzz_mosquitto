```md
# ChatAFL + Mosquitto Fuzz Guide (Poe LLM Version)

This project is used to run **ChatAFL** inside a Docker environment and fuzz **Eclipse Mosquitto (MQTT Broker)** as the target.

You will receive two files:

- `chatafl.zip`
- `Dockerfile`

---

## 1. Unzip `chatafl.zip`

Put `chatafl.zip` and `Dockerfile` in the same directory, then unzip:

```bash
unzip chatafl.zip
```

After unzipping, you should have a `chatafl/` directory.

---

## 2. Build the Docker image with the Dockerfile

In the directory that contains the `Dockerfile`, run:

```bash
docker build -t chatafl:latest .
```

After the build finishes, run the container (example: interactive shell):

```bash
docker run --rm -it chatafl:latest /bin/bash
```

> Note: If you want to mount `chatafl/` from your host into the container, use `-v`. If the Dockerfile already copies everything into the image, you don’t need to mount anything.

---

## 3. Inside the container: switch directory and configure the Poe key

After entering the container, switch to the ChatAFL directory first:

```bash
cd /opt/chatafl
```

Edit `chat-llm.h` and replace the key with your own **Poe API key**:

```bash
vim chat-llm.h
# or use nano
# nano chat-llm.h
```

---

## 4. If you want to use a different LLM / endpoint

The current implementation uses Poe’s OpenAI-compatible endpoint (`base_url=https://api.poe.com/v1`).

If you want to use a different LLM (e.g., another compatible proxy or a different vendor API), modify:

- `chat-llm.c`, function `chat_with_llm()`  
  - update the request URL / headers / body format  
  - or adjust authentication and response parsing based on the target API

---

## 5. Build ChatAFL

In **`/opt/chatafl`**, run:

```bash
make clean all
```

After compilation, you can proceed to fuzzing.

---

## 6. Download and build the target: Eclipse Mosquitto

Inside the container, switch to `/opt`:

```bash
cd /opt
git clone https://github.com/eclipse/mosquitto.git
cd mosquitto
```

Set AFL + ASAN environment variables and build :

```bash
export AFL_USE_ASAN=1

CFLAGS="-g -O0 -fsanitize=address -fno-omit-frame-pointer" \
LDFLAGS="-g -O0 -fsanitize=address -fno-omit-frame-pointer" \
CC=afl-gcc make clean all WITH_TLS=no WITH_TLS_PSK:=no WITH_STATIC_LIBRARIES=yes WITH_DOCS=no WITH_CJSON=no WITH_EPOLL:=no
```

---

## 7. Start fuzzing (Mosquitto)

After building, go to `/opt/mosquitto` and run `afl-fuzz` :

```bash
cd /opt/mosquitto

afl-fuzz -d \
  -i /opt/chatafl/tutorials/mosquitto/in-mqtt \
  -o ./out-mqtt \
  -m none \
  -N tcp://127.0.0.1/1883 \
  -P MQTT \
  -D 10000 \
  -q 3 \
  -s 3 \
  -E -K -R \
  ./src/mosquitto
```

This will start fuzzing. The output directory is:

- `./out-mqtt`

---
