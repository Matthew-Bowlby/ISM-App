# ISM-App
Swift App built using Xcode.

## Workflow
- Users will be near the ESP32 to connect via Bluetooth LE. Once the ESP32 is in range, the `Connect` button is enabled.
  - First-time users will be prompted to enter a username to be displayed on the mirror. The username is then saved to Keychain to be used in future connections.
  - Once the user wants to disconnect, the `Connect` button turns into a `Disconnect` button. Once pressed, the app will disconnect from the ESP32.
- Once connected, the user can enter into the `Mirror Settings` tab to change various settings that will affect the mirror in some capacity:
  - The user's inputted username can be changed by pressing `Edit Username`. This will trigger an alert similar to the one that displays on first-time connections to enter a new username. The new username replaces the old username in the Keychain.
  - The LED brightness slider controls the brightness of the vanity LED lights on the sides and back of the physical mirror.
  - The data to be collected can be turned on and off via a trigger. The two triggers regarding this are the Health and Weather data triggers.
  - Once the data is being collected, the trigger to send the data is enabled, which will send the data every minute after the first round of data is initially sent.
- Other settings:
  -  A selector to control the lighting theme in the app purely for user experience.
  -  A debug text that shows a searching animation when searching for the ESP32 as well as the most recently discovered peripheral over Bluetooth LE.
    
## Bluetooth LE
- Uses the CoreBluetooth framework.
- Implements Bluetooth LE to send various information over to the ESP32.
  - Data is encrypted using AES-128 in CBC mode. The key and IV were generated via a cryptographic random number generator.
  - AES was provided through the CommonCrypto framework.

## Health Data
- Uses the HealthKit framework.
- Uses asynchronous processes to retrieve various data points from the Apple Health App.
  - Data points depend on user permissions, where the user can choose which data points they want to share with the app.
  - Data points include heart rate, calories burned, step count, and distance walked.
- Once the data points are retrieved, they are appended to be sent every minute via Bluetooth LE to the ESP32.

## Weather Data
- Uses the WeatherKit framework.
- Grabs the current weather information from the weather app.
  - Data points are temperature, humidity, condition, and UV index.
- Awaits until all are retrieved, then appends the data to be sent every minute via Bluetooth LE to the ESP32.
