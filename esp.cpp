#include <ESP8266WiFi.h>
#include <FirebaseArduino.h>

#define FIREBASE_HOST "yourfirebase.firebaseio.com"
#define FIREBASE_AUTH "specz-d79eb"
#define FIREBASE_KEY "firebase-adminsdk-oxa2r@specz-d79eb.iam.gserviceaccount.com"
#define FIREBASE_KEY_ID "098f954114dad00e65aa6f3a3fbc1bccef2fab90"
#define FIREBASE_PRIVATE_KEY "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDKXMguB2aHr3Ck\nbeM0TU1mPbJ0SLz4XRWF6bw9eQdqxb4CAc5gvAEbGzhTmpdCZyJN/5cwJSXrN71l\nw7Sqzal0qUoUG5nmbdGZvvEJc2K0q7GI8iWd8AMYB3W3mAvDTBcRzfHDYN4mBhkC\n/yqylfBZgRMhNbG82befPuzyw4Wh/nl01pGsTMbV87LxQsH5T6susImdml6WS7YS\n1RvTnOeC/zcae32qYCryZFHELbmgLzNxLHYZtPfMOqrvDSSvWyBd5rQx0yWzIA76\n2f3kP28ZDcRrNj1z9zH4C06COMQw7E5D9Fgh5/69m4JbzLz6C3xtJt0kzntoJjWT\nkNTtrL3vAgMBAAECggEACoMkYQPAZ0cNXnVY6rQjU67b0N+gdXR8dD7uqPDbGkhY\ndQk7+9l4YzyYQfuTZP8vkIa5B2a+oAf+vkUa4w6ZAXbz4rSGW6qTy11Ybym/1Gvg\n5qDRpHE97+cfTeDHp6cRwbqFlyU2lRoW/Ylc4fcZC8VBRaXg7FMRD2Q48emHTSFv\n5+WpMXqLhFQRFXkClXV7Ihto6d8m1g7zE+iH8fSfUVDsJpS23hqBrKOSkT3mTD+1\ns9PbBLvvSGWlLtYCdVdYuS3rp4Wr5vrk3HcjOqwBOAbEccOGwNg66mmspgZNPzkT\nlbzRtXRafZYrZahdJQGHcFsOLiQFjltIxyCklaZNEQKBgQDu5HJXJuMcKTgeqvqa\nxn7vF5iLCQlSNrHPpwpfoO3IHaI0pU6D8Jvk53gg67wfWqNigG2oiFdVjmOwXtQe\nQLpObOXtu0U3u99GTjYUFTjZ/vWo6gNaU5sc4MClqEeK+sV1knuzgve5RrEG4+4S\nUk8q/JGUCL56ZMmSji8HQceRXwKBgQDY2qQjIAhT30HYgrsyVGKHtebHLahrELNX\n3OBdV0x8ALKCI0yGA84kCzRv8p0sxvSafyjWxb4ILjRm65HYbJzUdV9OrrNE9F+W\nh7hGw3c7bhZq8gfMpyWydmfxeW8KjSpIQici2hytidC6uEq8ctK68ktUOUKrmenX\nlrOZY6RNcQKBgAhpuy0ejXj8aqGJ2/F/dBDvf8vFsbJXgsORWmgrvrQBdyjreWxk\nGNli3XQrWSCxjHd3lmUNCCZXMWOQs1+tX+JLK33HzpQ75Y0QTA9BABONSxF7zEpu\nD1RhBefPmVVnp3SQiBK2VgsMVker10KF64vUATx5YlvlGMQ0hat3wZN5AoGBAM6/\nrev7N1VXrvyQr48tmv8Oc2eE5WSmeIaVhKgZekdjls2yf9vpttjwgd8VrbqqOT0v\nbS1PPH2qJ7XUdKml6+Q3v1VSBIMChjwLS6rT41KbA+6UsNDyr2M1tqYoA7FIo35e\n69czolHl6kaLPF3tD3LDXQSAz0qyJJuyB6t/r39RAoGBAMeeDRE1cRw3n4nqrBaM\nHViGqsLWxggjSiY2mSnYLWGNRjsh+//ACZeOdXTOA6PjRpML9Dpg8hLp1PLemXyQ\nYONJPsNfP8L66xqFve9Tqva8+CRKXddbYil6ZMpaX7WFxCoBUiXwq4JKMvrhR54S\n2EQ8f6UVhaofifvymSrkjzZf\n-----END PRIVATE KEY-----\n",
  "client_id": "103719962513700894033",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-oxa2r%40specz-d79eb.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}

// Set WiFi credentials
#define WIFI_SSID "yourwifissid"
#define WIFI_PASSWORD "yourwifipassword"

void setup() {
  Serial.begin(115200);

  // Connect to WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("WiFi connected.");

  // Initialize Firebase
  Firebase.begin(FIREBASE_HOST, FIREBASE_AUTH, FIREBASE_KEY, FIREBASE_KEY_ID, FIREBASE_PRIVATE_KEY);
}

void loop() {
  // Retrieve the latest data from Firebase
  FirebaseObject data = Firebase.get("/transcript", "/.json?orderBy=\"$key\"&limitToLast=1");
  if (data.success()) {
    Serial.println("Latest Data from Firebase:");
    Serial.println(data.jsonString());
  } else {
    Serial.println("Failed to retrieve data from Firebase.");
  }

  delay(5000); // wait for 5 seconds before retrieving data again
}
