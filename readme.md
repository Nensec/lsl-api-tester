# V's Tester
Latest version can always be found on github: https://github.com/Nensec/lsl-api-tester
Feel free to modify and redistribute this script however you please, I simply ask that you keep my name as the original author by keeping the changelog intact and simply add your own changelog.

## Changelog

- v1.3.0 - Voisin (Nensec Resident)
    - Removed ASSERT's option to listen to channel, you can't listen to yourself so this will never work
    - Optionally separated out loading of the notecard and parsing it into a separate ApiTester_Loader.lsl script
    - Added new action type EXPECTRLV which allows the tester to check if an RLV restriction is present
    - Added new action type WAIT which allows the tester to wait for a specified amount of time before proceeding to the next task
- v1.2.2 - Voisin (Nensec Resident)
    - Various small fixes and inconsistensies
    - Added NULL and THIS placeholders
- v1.2.1 - Voisin (Nensec Resident)
    - Swapped parameters 1 and 2 around for ASSERT
    - ASSERT channels are now properly listen'd for on test start
- v1.2.0 - Voisin (Nensec Resident)
    - Added new action type ASSERT
    - Added falsey test for EXPECT
- v1.1.2 - Voisin (Nensec Resident)
    - Fixed bug in EXPECT.
    - Removed touch events in favor of commands
- v1.1.1 - Voisin (Nensec Resident)
    - Various bug fixes and optimizations
- v1.1.0 - Voisin (Nensec Resident)
    - Removed Boost framework and made tester completely notecard based, removing the need for a runner script
- v1.0.0 - Voisin (Nensec Resident)
    - Initial version

## What is it

The purpose of this script is to help automate the testing of your API. It does so by using pre-defined blocks of code to define what a test is and what it should do.
By using pre-defined blocks you eliminate, or at least heavily reduce, contamination of copy pasting or other code. You are also ensured that every time you use that block it will do the same thing.

## How to use

If you received this script stand alone you need it's companion script: ApiTester_Relay.lsl.
All scripts, and thus its latest versions, can be found at on my github: https://github.com/Nensec/lsl-api-tester
As this script is meant for developers, I welcome forking and subsequent pull requests with modifications!

The tester has 3 objects that it uses.
 - The tester object. ApiTester.lsl lives in here.
 - A rezzable object. ApiTester_Relay.lsl lives in here. This object is meant to be rezzed, as such it requires to be Copy/Modify.
 - An attachable object. ApiTester_Relay.lsl lives in here as well. This object is meant to be temporary attached, as such it also requires to be Copy/Modify.

The rezzable object and attachable object need to be in the inventory of the tester object.

To configure the tester simply modify the output of the macros according to the comments, some things do not need to be changed whilst other things will according to your API needs.

## Commands

The tester utilizes a set of chat commands that allow you to drive the tester, commands are received on COMMAND_CHANNEL (default /9):

| Command | Description |
| :--- | :--- |
| `/9 load <testsuite>` | Loads the test suite with the given name, names are equal to the notecard that defines them |
| `/9 suites` | Displays all the currently loaded test suites that are available |
| `/9 reload` | Reloads all the notecards, wipes the LSD of existing data regarding notecards. Can only be used from the default start |
| `/9 loadtest <testname>` | Removes all tests from the currently loaded test suite except for the given name, allowing you to run just this one test |
| `/9 report` | Reports the test results after a test suite has finished. Can only be used from the report state |
| `/9 mem` | Reports on the current memory usage of the script |
| `/9 reset` | Script resets `ApiTester.lsl` |
| `/9 stop` | Only available during a test run, gracefully stops the current test suite as soon as possible |

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
    - **integer** inverse *(inverts the logic if true (not 0), fails test if message is found)*
- Types:
    - 0: *(Beginning of test)*
    - 1: *(Since last SEND)*
    - 2: *(Since last RELAY)*

### RELAY (4)
Instructs a given Relay object to relay a message.
- Parameters:
    - **key** relay
    - **integer** channel
    - **string** message
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

### ASSERT (6)
Sends a message that is meant to be received by the `<testsuite>_PH.lsl` script as a link message. It can then do any kind of custom parsing and comparison it wants.

The message will be in JSON format, according to the scheme found in [assert.schema.json](https://github.com/Nensec/lsl-api-tester/blob/master/assert.schema.json)
The ASSERT will be send to the processing helper script after waitTime has passed.

The tester expects a message back as a link message with the provided token as well as the answer of `fail` or `ok` prefixed with the `assert` command.
The tester will wait for a maximum of 500ms for a reply back.

### EXPECTRLV (7)
Uses `@getstatusall` to check if a specific RLV restriction is present and compares it, optionally, to a supplied value. If no value is provided only checks if the restriction is present.
- Parameters:
    - **string** restriction
    - **string** value (optional)

### WAIT (8)
Causes the test to wait for a specified amount of time before continuing on with the next task.
- Parameters:
    - **integer** waitTime (in milliseconds)

Example: `assert 7321d897-ad5f-f98c-11ea-f5a56e2399ff ok`
- Parameters:
    - **integer** waitTime *(in milliseconds)*
    - **integer** channel
    - **integer** type
- Types:
    - 0: *(Beginning of test)*
    - 1: *(Since last SEND)*
    - 2: *(Since last RELAY)*

# Placeholders
All parameters for actions have the ability to be replaced dynamically by a different value, something that is generally not known as a constant. These are called `placeholders` and you can refer to them in your actions using the `$` symbol as a prefix. The tester, by default, has two placeholders already defined that you can use:

| Placeholder | Description |
| :--- | :--- |
| `AV` | The avatar's UUID. |
| `TESTCHANNEL` | The integer that was defined as part of the TEST_CHANNEL macro in the configuration section |
| `NULL` | The equivalent of NULL_KEY |
| `THIS` | The UUID of the prim that ApiTester.lsl is in |

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
Adjust the tester's behavior by modifying the `#define` macros at the top of the script.

| Macro | Default | Description |
| :--- | :--- | :--- |
| `TEST_CHANNEL` | `-8378464` | Communication channel for tests/relays. Filtered by owner ID. |
| `COMMAND_CHANNEL` | `9` | Channel for user chat commands (e.g. `/9 reload`). |
| `ASK_TYPE` | `ASK_TYPE_DIALOG` | Use `ASK_TYPE_CHAT` for text or `ASK_TYPE_DIALOG` for buttons. |
| `DUMMY_OBJECT` | `"Dummy"` | Name of the Relay object to rez from inventory. |
| `DUMMY_ROTATION` | `<90, 270, 0>` | Facing direction of the rezzed dummy. |
| `DUMMY_HEIGHT` | `0.64528` | Height offset to ensure the dummy rezes on the floor. |
| `DUMMY_ATTACH` | `"Attach"` | Name of the object to rez and attach to the avatar. |
| `ATTACH_POINT` | `35` | The attachment point ID used for dummies. |