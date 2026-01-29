# V's Tester
Latest version can always be found on github: https://github.com/Nensec/lsl-api-tester
Feel free to modify and redistribute this script however you please, I simply ask that you keep my name as the original author by keeping the changelog intact and simply add your own changelog.

## Changelog

v1.0: Initial version - Voisin (Nensec Resident)

## What is it

The purpose of this script is to help automate the testing of your API. It does so by using pre-defined blocks of code to define what a test is and what it should do.
By using pre-defined blocks you eliminate, or at least heavily reduce, contamination of copy pasting or other code. You are also ensured that every time you use that block it will do the same thing.


This tester script is in part self-generating, all you have to do is define data and the code will be generated using the Boost preprocessor.
The resulting compiled code is, as a result, less than stellar to read. If you do not have a preprocessor enabled and was given this script, that would be why.
As such in order to compile this script you need to have the Boost files ready on your local hard drive and have your preprocessor configured to find these files
In Firestorm, where this script is build for, you just have to ensure that your include path has access to the boost folder in its root such that the above #include's are correct.
You can of course alter the includes above to match your folder structure.

Boost can be downloaded from here: https://www.boost.org/releases/latest/
I suggest grabbing a zip and just unpack it where you need it.

## How to use

If you received this script stand alone you need it's companion script: ApiTester_Relay.lsl.

**COMING SOON in v1.1** Additionally, if your test suite is so large that this script runs into memory problems and stack heaps you can instead use the runner mode option and require the ApiTester_Runner.lsl script

All scripts, and thus its latest versions, can be found at on my github: https://github.com/Nensec/lsl-api-tester
As this script is meant for developers, I welcome forking and subsequent pull requests with modifications!

The tester has 3 objects that it uses.
 - The tester object. ApiTester.lsl and ApiTester_Runner.lsl live in here. (The latter is optional and dependant on configuration here!)
 - A rezzable object. ApiTester_Relay.lsl lives in here. This object is meant to be rezzed, as such it requires to be Copy/Modify.
 - An attachable object. ApiTester_Relay.lsl lives in here as well. This object is meant to be temporary attached, as such it also requires to be Copy/Modify.

The rezzable object and attachable object need to be in the inventory of the tester object.

To configure the tester simply modify the output of the macros according to the comments, some things do not need to be changed whilst other things will according to your API needs.

## Defining tests

Define tests and their actions, these tell a 'story'. e.g. "After we SEND add Tester we EXPECT to return add-confirm." or "After we SEND remove Tester we ASK Did the device manager report the device \"Tester\" was removed?"

The first parameter of the tuple is the name of the test, no spaces allowed.
The second parameter of the tiple is a list of dependencies, this allows you to skip tests if you know they will fail because it's function is reliant on another test being succesful
The third parameter of the tuple is a list of tuples that define actions to be executed for this test.

Note: You need to double up the brackets.

Example:
```c
#define TEST_DATA \
        (("ADD_AND_REMOVE", ([]), ((COMMON_ADD_TESTER))((COMMON_WAIT_FOR_CONFIRM))((COMMON_REMOVE_TESTER))(("Ask if device removed", ACTION_ASK, "Did the device get removed?")) )) \
        (("ADDCOMMAND", (["ADD_AND_REMOVE"]), ((COMMON_ADD_TESTER))((COMMON_WAIT_FOR_CONFIRM))(("Send add command", ACTION_SEND, "$AV", "$IB", "add-command Test"))(("Ask if command added", ACTION_ASK, "Did the command get added?"))(("Remove commands command", ACTION_SEND, "$AV", "$IB", "remove-commands"))(("Ask if commands removed", ACTION_ASK, "Did the command get removed?"))((COMMON_REMOVE_TESTER)) ))
```

Placeholders are supported, data gets retrieved from LSD. Starting a string using a $ tells the test script to fetch that name from LSD. If not then the raw value is used.
See the SETUPPLACEHOLDERS() macro for available placeholders

The parameters are as follows:

    Name, Action Type, First Parameter, Second Parameter, Third Parameter, Fourth Parameter

The name gets output in the log.
It is recommended to use the macros for the actions, to ensure there are no typos. Simply prepend ACTION_ to the type of action to use the macro version. e.g. `ACTION_SEND` or `ACTION_EXPECT`.

#### Common actions

Define common functions that are required in many tests, this will save on script memory because these will only be generated once.
They follow the same pattern as actions in the TEST_DATA macro, where the name is the key of the function. I recommend making macros for the keys so you can easily use them without typos.
These functions usually correspond to stand alone tests, where those tests then become dependencies of future tests.
For example: Your API requires a script to announce itself first before it will accept a command from the script, rather than writing the full ACTION_SEND to authenticate as part of the test data simply define it once here and use it in place of an action.

Example:
```c
#define COMMON_ACTIONS \
        ((COMMON_ADD_TESTER, "Add tester", ACTION_SEND, "$AV", "$IB", "add Tester")) /* Adds a device */ \
        ((COMMON_WAIT_FOR_CONFIRM, "Confirm add", ACTION_EXPECT, "$IB", "add-confirm", 500, EXPECT_TYPE_SEND)) /* Ensures the device is added by waiting for add-confirm */ \
        ((COMMON_REMOVE_TESTER, "Remove tester", ACTION_SEND, "$AV", "$IB", "remove Tester")) /* Removes the device */
```
## Available actions:

### SEND
Send a message on a channel to kick off the test.
- Parameters:
    - **key** target
    - **integer** channel
    - **string** message

### EXPECT:
Assert a certain value is returned since beginning of test, SEND or RELAY. If a * is added any remaining string after the * is ignored. Useful for commands that return a value not known ahead of time, but do fit a pattern.
- Parameters:
    - **integer** channel
    - **string** value
    - **integer** time *(in milliseconds)*
    - **integer** type
- Types:
    - EXPECT_TYPE_BEGINNING *(Beginning of test)*
    - EXPECT_TYPE_SEND *(Since last SEND)*
    - EXPECT_TYPE_RELAY *(Since last RELAY)*

### ASK
Ask a Yes/No question, if answered with No then the test is marked as failed.
- Parameters:
    - **string** message

### REZ
Rezzes a Relay object. It's name gets added to LSD as a placeholder with the value being its UUID. The Relay object houses a simple relaying script that allows the RELAY function to send messages via the Relay object.
- Names however need to be unique for each.
- Parameters:
    - **string** name
    - **float distance** *(max 10, SL limit)*

### ATTACH
Attaches a Relay object. It's name gets added to LSD as a placeholder with the value being its UUID. The Relay object houses a simple relaying script that allows the RELAY function to send messages via the Relay object.
- Names however need to be unique for each.
- Parameters:
    - **string** name

### RELAY
Instructs a given Relay object to relay a message.
- Parameters:
    - **key** relay
    - **integer** channel
    - **string** value
    - **integer** channelType
- Types:
    - RELAY_TYPE_REGIONSAYTO: RegionSayTo *(target = llGetOwner)*
    - RELAY_TYPE_SAY: llSay
    - RELAY_TYPE_WHISPER: llWhisper
    - RELAY_TYPE_SHOUT: llShout

# Placeholders
Add a new llLinksetDataWrite for every placeholder you want to add, you can always call a function as well if something is especially complex to calculate.
Where applicable you can insert these placeholder values by prefixing its name with a $ symbol.

Example:
```c
#define SETUPPLACEHOLDERS() \
        llLinksetDataWrite("AV", llGetOwner()); \
        llLinksetDataWrite("IB", (string)(-1 - (integer)("0x" + llGetSubString((string)llGetOwner(), -7, -1)) + 5515));
```
Note: the LSD is wiped on every rez and re-filled during initialization of the tester.

Tip: Rather than define all of your tests in this script and keep copies of this entire script around, simply make them in a separate file and #include <yourtests.lsl>.
Just `#define TEST_DATA`, `#define COMMON_ACTIONS` and `#define SETUPPLACEHOLDERS()` in there and comment them out in the main script here.
That way you only need to change one line of code to change your entire test suite!

# Tester configuration
Run the script locally (TESTER_MODE_LOCAL) in just this script or use a runner script (TESTER_MODE_RUNNER) that contains all the logic, this will save on memory but uses link messages to control the test flow.

    #define TESTER_MODE TESTER_MODE_LOCAL
This is the channel that the tests and relay communicate on, all listeners are filtered by owner avatar id.

    #define TEST_CHANNEL -8378464
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