# V's Tester
Latest version can always be found on github: https://github.com/Nensec/lsl-api-tester
Feel free to modify and redistribute this script however you please, I simply ask that you keep my name as the original author by keeping the changelog intact and simply add your own changelog.

## Changelog

- v1.0: Initial version - Voisin (Nensec Resident)
- v1.1: Removed Boost framework and made tester completely notecard based, removing the need for a runner script - Voisin (Nensec Resident)
- v1.1.1: Various bug fixes and optimizations - Voisin (Nensec Resident)

## What is it

The purpose of this script is to help automate the testing of your API. It does so by using pre-defined blocks of code to define what a test is and what it should do.
By using pre-defined blocks you eliminate, or at least heavily reduce, contamination of copy pasting or other code. You are also ensured that every time you use that block it will do the same thing.

## How to use

If you received this script stand alone you need it's companion script: ApiTester_Relay.lsl.
All scripts, and thus its latest versions, can be found at on my github: https://github.com/Nensec/lsl-api-tester
As this script is meant for developers, I welcome forking and subsequent pull requests with modifications!

The tester has 3 objects that it uses.
 - The tester object. ApiTester.lsl and ApiTester_Runner.lsl live in here. (The latter is optional and dependant on configuration here!)
 - A rezzable object. ApiTester_Relay.lsl lives in here. This object is meant to be rezzed, as such it requires to be Copy/Modify.
 - An attachable object. ApiTester_Relay.lsl lives in here as well. This object is meant to be temporary attached, as such it also requires to be Copy/Modify.

The rezzable object and attachable object need to be in the inventory of the tester object.

To configure the tester simply modify the output of the macros according to the comments, some things do not need to be changed whilst other things will according to your API needs.

## Defining tests

Test are loaded via notecard and are formatted in JSON. You can write them in your IDE of choice that allows for JSON syntax validation and then simply copy over the text into the notecard. There is a schema available in the repository, you can point your test suite towards it to validate it to what the tester expects. Simply add:
```json
{ "$schema": "https://raw.githubusercontent.com/Nensec/lsl-api-tester/refs/heads/master/test-suite.schema.json" }
```
Note: This schema is ignored by the tester when parsing in-game, you can leave it in your notecard.

#### Common actions

Define common functions that are required in many tests, this helps reducing the repetitiveness and ensure that you are generally doing the same thing.

For example: Your API requires a script to announce itself first before it will accept a command from the script, rather than writing the full SEND to authenticate as part of the test data simply define it once there and use it in place of an action.

## Available actions:

### SEND (0)
Send a message on a channel to kick off the test.
- Parameters:
    - **key** target
    - **integer** channel
    - **string** message

### ASK (1)
Ask a Yes/No question, if answered with No then the test is marked as failed.
- Parameters:
    - **string** message

### REZ (2)
Rezzes a Relay object. It's name gets added to LSD as a placeholder with the value being its UUID. The Relay object houses a simple relaying script that allows the RELAY function to send messages via the Relay object.
- Names however need to be unique for each.
- Parameters:
    - **string** name
    - **float distance** *(max 10, SL limit)*

### EXPECT (3)
Assert a certain value is returned since beginning of test, SEND or RELAY. If a * is added any remaining string after the * is ignored. Useful for commands that return a value not known ahead of time, but do fit a pattern.
- Parameters:
    - **integer** channel
    - **string** value
    - **integer** time *(in milliseconds)*
    - **integer** type
- Types:
    - 0 *(Beginning of test)*
    - 1 *(Since last SEND)*
    - 2 *(Since last RELAY)*

### RELAY (4)
Instructs a given Relay object to relay a message.
- Parameters:
    - **key** relay
    - **integer** channel
    - **string** value
    - **integer** channelType
- Types:
    - 0: RegionSayTo *(target = llGetOwner)*
    - 1: llSay
    - 2: llWhisper
    - 3: llShout

### ATTACH (5)
Attaches a Relay object. It's name gets added to LSD as a placeholder with the value being its UUID. The Relay object houses a simple relaying script that allows the RELAY function to send messages via the Relay object.
- Names however need to be unique for each.
- Parameters:
    - **string** name

# Placeholders
All parameters for actions have the ability to be replaced dynamically by a different value, something that is generally not known as a constant. These are called `placeholders` and you can refer to them in your actions using the `$` symbol as a prefix. The tester, by default, has two placeholders already defined that you can use:
- AV
    - The avatar's UUID
- TESTCHANNEL
    - The integer that was defined as part of the TEST_CHANNEL macro in the configuration section

## To add your own
Create a new script file that has the same name as your notecard but append the suffix `_PH` to it. Add a new llLinksetDataWrite for every placeholder you want to add, you can always call a function as well if something is especially complex to calculate.

Of course you can also modify the ApiTester.lsl as well and add them hard-coded if your value is used in many, or even all, of your test suites.

Example:
```lsl
default
{
    state_entry()
    {
        llLinksetDataWrite("IB", (string)(-1 - (integer)("0x" + llGetSubString((string)llGetOwner(), -7, -1)) + 5515));
    }
}
```
Note: the LSD is wiped on every rez and re-filled during initialization of the tester.

# Tester configuration
This is the channel that the tests and relay communicate on, all listeners are filtered by owner avatar id.

    #define TEST_CHANNEL -8378464
The tester responds to various commands, this channel is used for those commands. I recommend a low number as you will be typing this yourself in chat

    #define TEST_CHANNEL 9
Should the ASK action request a reply in a clickable chat message (ASK_TYPE_CHAT), or should it show a dialog with buttons (ASK_TYPE_DIALOG)?

    #define ASK_TYPE ASK_TYPE_DIALOG
The name of the Relay object to rez when REZ is used. This object has to exist in the inventory where this tester script lives and must contain the ApiTester_Relay.lsl script.

    #define DUMMY_OBJECT "Dummy"
Adjust the rotation of the dummy object so it faces a specific direction

    #define DUMMY_OBJECT_ROTATION <90.0, 270.0, 0.0> 
The height of the dummy object so REZ places it on the floor

    #define DUMMY_OBJECT_HEIGHT 0.64528
The name of the Relay object to rez and attach when ATTACH is used. This object has to exist in the inventory where this tester script lives and must contain the ApiTester_Relay.lsl script.

    #define DUMMY_ATTACH "Attach"
See https://wiki.secondlife.com/wiki/LlAttachToAvatar for attachment points

    #define DUMMY_ATTACH_POINT 35
