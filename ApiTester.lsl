// ####################################################################################
// -- Changelog, tester information, readme, and instructions to create a new tester --
// ####################################################################################

// V's Tester v1.1, by Voisin (Nensec Resident)

// Latest version can always be found on github: https://github.com/Nensec/lsl-api-tester
// Feel free to modify and redistribute this script however you please, I simply ask that you keep my name as the original author by keeping the changelog intact and simply add your own changelog.

// -- Changelog

// v1.0: Initial version - Voisin (Nensec Resident)
// v1.1: Removed Boost framework and made tester completely notecard based, removing the need for a runner script - Voisin (Nensec Resident)
// v1.1.1: Various bug fixes and optimizations - Voisin (Nensec Resident)
// v1.1.2: Fixed bug in EXPECT. Removed touch events in favor of commands - Voisin (Nensec Resident)
// v1.2: Added new action type ASSERT, Added falsey test for EXPECT - Voisin (Nensec Resident)

// -- What is it

// The purpose of this script is to help automate the testing of your API. It does so by using pre-defined blocks of code to define what a test is and what it should do.
// By using pre-defined blocks you eliminate, or at least heavily reduce, contamination of copy pasting or other code. You are also ensured that every time you use that block it will do the same thing.

// -- How to use

// If you received this script stand alone you need it's companion script: ApiTester_Relay.lsl.
// All scripts, and thus its latest versions, can be found at on my github: https://github.com/Nensec/lsl-api-tester
// As this script is meant for developers, I welcome forking and subsequent pull requests with modifications!

// The tester has 3 objects that it uses.
//  - The tester object. ApiTester.lsl lives in here.
//  - A rezzable object. ApiTester_Relay.lsl lives in here. This object is meant to be rezzed, as such it requires to be Copy/Modify.
//  - An attachable object. ApiTester_Relay.lsl lives in here as well. This object is meant to be temporary attached, as such it also requires to be Copy/Modify.
// The rezzable object and attachable object need to be in the inventory of the tester object.

// -- Commands

// The tester utilizes a set of chat commands that allow you to drive the tester, commands are received on COMMAND_CHANNEL (default /9):
// /9 load <testsuite> - Loads the test suite with the given name, names are equal to the notecard that defines them
// /9 suites - Displays all the currently loaded test suites that are available
// /9 reload - Reloads all the notecards, wipes the LSD of existing data regarding notecards
// /9 loadtest <testname> - Removes all tests from the currently loaded test suite except for the given name, allowing you to run just this one test
// /9 report - Reports the test results after a test suite has finished
// /9 mem - Reports on the current memory usage of the script
// /9 reset - Script resets ApiTest.lsl
// /9 stop - Only available during a test run, gracefully stops the current test suite as soon as possible

// -- Defining tests

// Test are loaded via notecard and are formatted in JSON. You can write them in your IDE of choice that allows for JSON syntax validation and then simply copy over the text into the notecard.
// There is a schema available in the repository, you can point your test suite towards it to validate it to what the tester expects.
// Simply add:
// { "$schema": "https://raw.githubusercontent.com/Nensec/lsl-api-tester/refs/heads/master/test-suite.schema.json" }

// Note: This schema is ignored by the tester when parsing in-game, you can leave it in your notecard.

// - Common actions

// Define common functions that are required in many tests, this helps reducing the repetitiveness and ensure that you are generally doing the same thing.

// For example: Your API requires a script to announce itself first before it will accept a command from the script, rather than writing the full SEND to authenticate as part of the test data simply define it once there and use it in place of an action.

// -- Available actions:

// - SEND (0)
// Send a message on a channel to kick off the test.
// - Parameters:
//     - key target
//     - integer channel
//     - string message

// - ASK (1)
// Ask a Yes/No question, if answered with No then the test is marked as failed.
// - Parameters:
//     - string message

// -- REZ (2)
// Rezzes a Relay object. It's name gets added to LSD as a placeholder with the value being its UUID. The Relay object houses a simple relaying script that allows the RELAY function to send messages via the Relay object.
// - Names however need to be unique for each.
// - Parameters:
//     - string name
//     - float distance (max 10, SL limit)

// -- EXPECT (3)
// Assert a certain value is returned since beginning of test, SEND or RELAY. If a * is added any remaining string after the * is ignored. Useful for commands that return a value not known ahead of time, but do fit a pattern.
// - Parameters:
//     - integer channel
//     - string value
//     - integer time (in milliseconds)
//     - integer type
//     - integer inverse (inverts the logic if true (not 0), fails test if message is found)
// - Types:
//     - 0 (Beginning of test)
//     - 1 (Since last SEND)
//     - 2 (Since last RELAY)

// -- RELAY (4)
// Instructs a given Relay object to relay a message.
// - Parameters:
//     - key relay
//     - integer channel
//     - string value
//     - integer channelType
// - Types:
//     - 0: RegionSayTo (target = llGetOwner)
//     - 1: llSay
//     - 2: llWhisper
//     - 3: llShout

// -- ATTACH (5)
// Attaches a Relay object. It's name gets added to LSD as a placeholder with the value being its UUID.
// The Relay object houses a simple relaying script that allows the RELAY function to send messages via the Relay object.
// - Names however need to be unique for each.
// - Parameters:
//     - string name

// -- ASSERT (6)
// Sends a message that is meant to be recived by the <testsuite>_PH.lsl script. It can then do any kind of custom parsing and comparison it wants.
// By default this is send via llRegionSayTo to the owner of the tester object on channel TEST_CHANNEL. However if you notice that size of the JSON is an issue for you due to the volume of messages
// you can configure the tester to instead send it via llMessageLinked instead.
// The message will be in JSON format, according to the scheme found in assert.schema.json (this can be found on the github linked above)
// The ASSERT will be send to the processing helper script after waitTime has passed.
//
// The tester expects a message back on TEST_CHANNEL with the provided token as well as the answer of "fail" or "ok" prefixed with the "assert" command.
// The tester will wait for a maximum of 500ms for a reply back.
// Example: assert 7321d897-ad5f-f98c-11ea-f5a56e2399ff ok
//
// - Parameters:
//     - integer waitTime (in milliseconds)
//     - integer channel
//     - integer type
// - Types:
//     - 0 (Beginning of test)
//     - 1 (Since last SEND)
//     - 2 (Since last RELAY)

// - Placeholders
// All parameters for actions have the ability to be replaced dynamically by a different value, something that is generally not known as a constant.
// These are called `placeholders` and you can refer to them in your actions using the `$` symbol as a prefix. The tester, by default, has two placeholders already defined that you can use:
// - AV
//     - The avatar's UUID
// - TESTCHANNEL
//     - The integer that was defined as part of the TEST_CHANNEL macro in the configuration section

// -- To add your own
// Create a new script file that has the same name as your notecard but append the suffix `_PH` to it.
// Add a new llLinksetDataWrite for every placeholder you want to add, you can always call a function as well if something is especially complex to calculate.

// Of course you can also modify the ApiTester.lsl as well and add them hard-coded if your value is used in many, or even all, of your test suites.

// Example:

// default
// {
//     state_entry()
//     {
//         llLinksetDataWrite("IB", (string)(-1 - (integer)("0x" + llGetSubString((string)llGetOwner(), -7, -1)) + 5515));
//     }
// }

// Note: the LSD is wiped on every rez and re-filled during initialization of the tester.

// ####################################################################################
// -- Adjust the macro outputs to your testing needs by following instructions below --
// ####################################################################################

// Turn off which logging you do not want by commenting out the log level. Turning all off will result in only the test result to be output.
// Turning off logging will help a lot in script memory, it is recommended to only turn on logging when you are experiencing problems. Additionally use the /9 loadtest <testname> command to load only the problematic test.
// Logging adds a lot of memory!

//#define INFO
//#define VERBOSE
//#define LISTENER // This will dump all content you receive from listeners you have specified in EXPECT's in a test, it can be very spammy depending on how much chatter you have on your channel(s)!

// Tester configuration
#define TEST_CHANNEL -8378464 // This is the channel that the tests and relay communicate on, all listeners are filtered by owner avatar id.
#define COMMAND_CHANNEL 9 // This is the channel where the tester receives user commands on

#define ASK_TYPE ASK_TYPE_DIALOG // Should the ASK action request a reply in a clickable chat message (ASK_TYPE_CHAT), or should it show a dialog with buttons (ASK_TYPE_DIALOG)?

#define DUMMY_OBJECT "Dummy" // The name of the Relay object to rez when REZ is used. This object has to exist in the inventory where this tester script lives and must contain the ApiTester_Relay.lsl script.
#define DUMMY_OBJECT_ROTATION <90.0, 270.0, 0.0> // Adjust the rotation of the dummy object so it faces a specific direction
#define DUMMY_OBJECT_HEIGHT 0.64528 // The height of the dummy object so REZ places it on the floor

#define DUMMY_ATTACH "Attach" // The name of the Relay object to rez and attach when ATTACH is used. This object has to exist in the inventory where this tester script lives and must contain the ApiTester_Relay.lsl script.
#define DUMMY_ATTACH_POINT 35 // See https://wiki.secondlife.com/wiki/LlAttachToAvatar for attachment points

#define ASSERT_SEND_METHOD ASSERT_SEND_METHOD_CHAT // The method used to send ASSERT messages to the helper script, either via chat (ASSERT_SEND_METHOD_CHAT) on channel TEST_CHANNEL or via link message (ASSERT_SEND_METHOD_LINK) or have the processing helper script decide (ASSERT_SEND_METHOD_PH). This will add additional bytecode to support both methods.
#define ASSERT_REPLY_TIMEOUT 500 // The time how long the tester will wait for the processing helper script to reply to ASSERT

// ####################################################################################
// -- Below here should not be edited by the user unless you know what you are doing --
// ####################################################################################

// Tester constants
#define _ ""
#define STR(...) #__VA_ARGS__
#define DEFER_STR(...) STR(__VA_ARGS__)

#define TESTSTATE_IDLE 0
#define TESTSTATE_SUCCESS 1
#define TESTSTATE_FAILURE 2
#define TESTSTATE_INITIALIZING 3
#define TESTSTATE_RUNNING 4
#define TESTSTATE_CANCELLED 5

#define TASKSTATE_IDLE 0
#define TASKSTATE_SUCCESS 1
#define TASKSTATE_FAILURE 2
#define TASKSTATE_WAITING 3

#define ACTION_SEND 0
#define ACTION_ASK 1
#define ACTION_REZ 2
#define ACTION_EXPECT 3
#define ACTION_RELAY 4
#define ACTION_ATTACH 5
#define ACTION_ASSERT 6

#define ASK_YES "Yes"
#define ASK_NO "No"
#define ASK_TYPE_CHAT 0
#define ASK_TYPE_DIALOG 1

#define RELAY_COMMAND_DIE "die"
#define RELAY_COMMAND_INIT "init"
#define RELAY_COMMAND_RELAY "relay"
#define RELAY_COMMAND_ATTACH "attach"
#define RELAY_TYPE_REGIONSAYTO 0
#define RELAY_TYPE_SAY 1
#define RELAY_TYPE_WHISPER 2
#define RELAY_TYPE_SHOUT 3

#define EXPECT_TYPE_BEGINNING 0
#define EXPECT_TYPE_SEND 1
#define EXPECT_TYPE_RELAY 2

#define ASSERT_OK "ok"
#define ASSERT_FAIL "fail"
#define ASSERT_REPLY "assert"
#define ASSERT_SEND_METHOD_CHAT 0
#define ASSERT_SEND_METHOD_LINK 1
#define ASSERT_SEND_METHOD_PH 2
#define ASSERT_TYPE_BEGINNING 0
#define ASSERT_TYPE_SEND 1
#define ASSERT_TYPE_RELAY 2

#define COMMAND_LOAD load
#define COMMAND_RELOAD reload
#define COMMAND_START start
#define COMMAND_SUITES suites
#define COMMAND_MEM mem
#define COMMAND_STOP stop
#define COMMAND_REPORT report
#define COMMAND_RESET reset
#define COMMAND_LOADTEST loadtest

#define INVALID_PLACEHOLDER JSON_INVALID

#define DEFAULT_PLACEHOLDERS \
        llLinksetDataWrite("AV", llGetOwner()); \
        llLinksetDataWrite("TESTCHANNEL", (string)TEST_CHANNEL);

#define COMMON_ACTIONS \
        llLinksetDataWrite("C_REZ_DUMMY", DEFER_STR({"name":"Rez dummy","actionType":ACTION_REZ,"parameters":["DUMMY",2.5]})); \
        llLinksetDataWrite("C_ATTACH_DUMMY", DEFER_STR({"name":"Attach dummy","actionType":ACTION_ATTACH,"parameters":["ATTACH"]}));

// -- Global variables

string _currentSuite;
list _tests = []; // Currently loaded test suite, or notecard queries (to save memory)

integer _activeTest = -1; // Index of current test
integer _activeTestState = TESTSTATE_IDLE; // Current state of the test

integer _currentTask = 0; // The current task
string _currentTaskData; // JSON data of current task
integer _currentTaskState = TASKSTATE_IDLE; // Current state of the current task
string _currentTaskFailureMessage;

list _receivedMessage = []; // Strided list of 3: [message, channel, timestamp]
list _rezzedDummies = []; // All of the dummies rezzed during the current test

// Parameters are global, this is to lower memory fragmentation
string  _currentActionParam1; // Parameter 1 of current action
string  _currentActionParam2; // Parameter 2 of current action
string  _currentActionParam3; // Parameter 3 of current action
string  _currentActionParam4; // Parameter 4 of current action
string  _currentActionParam5; // Parameter 5 of current action

float _rezTime; // When was the last REZ
float _sendTime; // When was the last SEND
float _relayTime; // when was the last RELAY
float _askTime; // when was the last ASK
float _assertTime; // When was the last ASSERT

#if ASSERT_SEND_METHOD == ASSERT_SEND_METHOD_PH
integer _assertSendType; // This is only present when ASSERT_SEND_METHOD is _PH and keeps track of what assert type the PH script wants (chat or link)
#endif
key _assertToken; // This is the token given to the PH script to do its ASSERT logic, the token is compared upon receiving an answer such that the reply is linked to the correct ASSERT (in case of a timeout)

float _timeToCheck; // Bytecode saver since this is used twice now

integer _expectLastMessageIndex; // This helps keep script time lower by keeping track what EXPECT already checked in between timer loops so we aren't going over the entire _receivedMessage list every 0.1 sec

// Logging

log(string msg) { if(_activeTestState != TESTSTATE_IDLE) llOwnerSay("[V's Tester] [" + (string)_tests[_activeTest] + "] " + msg); else llOwnerSay("[V's Tester] " + msg); }
#ifdef INFO
    logInfo(string msg) { log("[INFO] " + msg); }
#else
    #define logInfo(msg)
#endif
#ifdef VERBOSE
    logVerbose(string msg) { log("[VERBOSE] " + msg); }
#else
    #define logVerbose(msg)
#endif
#ifdef LISTENER
    logListener(string msg, integer channel, float time) { log("[LISTENER] [" + (string)channel + "] [" + (string)time + "] " + msg); }
#else
    #define logListener(msg, channel, time)
#endif

// Misc functions

string getParameter(string param)
{
    string result = "";
    integer i = llSubStringIndex(param, "$");

    while(~i)
    {
        if(i != 0)
            result += llGetSubString(param, 0, i - 1);
        param = llGetSubString(param, i + 1, -1);

        integer space = llSubStringIndex(param, " ");
        string placeholder;
        
        if(~space)
        {
            placeholder = llGetSubString(param, 0, space - 1);
            param = llGetSubString(param, space, -1);
        }
        else
        {
            placeholder = param;
            param = "";
        }

        string lsdPlaceholder = llLinksetDataRead(placeholder);
        if(lsdPlaceholder)
        {
            result += lsdPlaceholder;
            i = llSubStringIndex(param, "$");
        }
        else
            return INVALID_PLACEHOLDER;
    }

    return result + param;
}

#if defined(INFO) || defined(VERBOSE)
reportTaskState()
{
    if(_currentTaskState == TASKSTATE_SUCCESS)
        logInfo("Task success.");
    else if(_currentTaskState == TASKSTATE_FAILURE)
    {
        logInfo("Task failure.");
        logVerbose(_currentTaskFailureMessage);
    }
}
#else
#define reportTaskState()
#endif

loadNextTask()
{
    reportTaskState();

    if(_currentTaskData)
        _currentTask++;

    list actions = getTaskActions();

    if(_currentTask >= llGetListLength(actions))
        _activeTestState = TESTSTATE_SUCCESS;
    else
    {
        _currentTaskData = (string)actions[_currentTask];

        _currentTaskState = TASKSTATE_IDLE;
        _currentTaskFailureMessage = "";

        _assertToken = NULL_KEY;
        _assertTime = 0;

        logInfo("Next task is: " + llJsonGetValue(_currentTaskData, ["name"]));
    }
}

list getTaskActions()
{
    list actions = llJson2List(llJsonGetValue(llLinksetDataRead("T_" + (string)_tests[_activeTest]), ["actions"]));
    integer i;
    integer len = llGetListLength(actions);
    for(i = 0; i < len; i++)
    {
        string action = (string)actions[i];
        if(llJsonValueType(action, []) != JSON_OBJECT)
            actions = llListReplaceList(actions, [llLinksetDataRead("C_" + action)], i, i);
    }
    return actions;
}

loadNotecards()
{
    _tests = [];
    _currentSuite = _;

    llLinksetDataDeleteFound("^NC_.*$", _);

    integer count = llGetInventoryNumber(INVENTORY_NOTECARD);
    if(count > 1)
        log("Found " + (string)count + " notecards, parsing them now..");
    else if(count == 0)
        log("No notecards found, add a notecard with test data to begin.");
    else
        log("Found 1 notecard, parsing it now..");

    string name;
    string queryId;
    while(count--)
    {
        name = llGetInventoryName(INVENTORY_NOTECARD, count);
        queryId = (string)llGetNotecardLine(name, 0);
        _tests += [name + ":" + queryId + ":0"];
        logVerbose("Parsing notecard: \"" + name + "\".");
    }
}

saveRezzedDummy(key id)
{
    logVerbose("Saving placeholder \"" + _currentActionParam1 + "\" with value: \"" + (string)id + "\".");
    llLinksetDataWrite(_currentActionParam1, id); // Save the rezzed object in LSD so it can be used as a placeholder
    llRegionSayTo(id, TEST_CHANNEL, RELAY_COMMAND_INIT + " " + _currentActionParam1);
    _rezzedDummies += [_currentActionParam1 + ":" + (string)id]; // Keep track of rezzed dummies so we can clean up memory and LSD at the end of the test
    _currentTaskState = TASKSTATE_SUCCESS;
}

killOtherScripts()
{
    integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
    string name;
    string thisScriptName = llGetScriptName();
    while(count--) // Kill other scripts in the tester object, this is to ensure there is no cross contamination as well as allow for PH scripts to do their init logic in default state_entry
    {
        name = llGetInventoryName(INVENTORY_SCRIPT, count);
        if(name != thisScriptName)
            llSetScriptState(name, FALSE);
    }
}

commandHandler(string message)
{
    list parts = llParseString2List(message, [" "], []);
    string cmd = (string)parts[0];
    if(cmd == DEFER_STR(COMMAND_RELOAD)) // Reloads all notecards, wiping currently loaded from LSD
        loadNotecards();
    else if(cmd == DEFER_STR(COMMAND_LOAD) && (string)parts[1] != "") // Loads a specific test suite, it's name must match that of the notecard originally read
    {
        string name = llDumpList2String(llList2List(parts, 1, -1), " ");
        string json = llLinksetDataRead("NC_" + name);
        if(llJsonValueType(json, []) != JSON_OBJECT)
            log("There is no suite called \"" + name + "\". " + DEFER_STR(View available suites using DEFER_STR(/COMMAND_CHANNEL COMMAND_SUITES)));
        else
        {
            logVerbose("Removing keys not associated with test suites..");
            llLinksetDataDeleteFound("^([^N]|N[^C]|NC[^_]).*$", _);

            logVerbose("Loading placeholders into LSD..");
            DEFAULT_PLACEHOLDERS
            logVerbose("Loading common actions into LSD..");
            COMMON_ACTIONS

            log("Loading test suite \"" + llJsonGetValue(json, ["name"]) + "\"");
            _tests = [];
            killOtherScripts();
            integer i;
            integer len;
            list jsonList = llJson2List(llJsonGetValue(json, ["commonActions"]));
            list jsonItem;
            len = llGetListLength(jsonList);
            for(i = 0; i < len; i++)
            {
                jsonItem = llJson2List((string)jsonList[i]);
                llLinksetDataWrite("C_" + (string)jsonItem[0], (string)jsonItem[1]);
            }
            jsonList = llJson2List(llJsonGetValue(json, ["tests"]));
            len = llGetListLength(jsonList);
            for(i = 0; i < len; i++)
            {
                jsonItem = llJson2List((string)jsonList[i]);
                llLinksetDataWrite("T_" + (string)jsonItem[0], (string)jsonItem[1]);
                _tests += [(string)jsonItem[0]];
            }
            _currentSuite = llJsonGetValue(json, ["name"]);
            if(llGetInventoryType(name + "_PH") == INVENTORY_SCRIPT)
            {
                llSetScriptState(name + "_PH", TRUE);
                llResetOtherScript(name + "_PH");
            }
            log(DEFER_STR(Loading finished. Use the command DEFER_STR(/COMMAND_CHANNEL COMMAND_START) to start the test suite));
        }
    }
    else if(cmd == DEFER_STR(COMMAND_LOADTEST) && (string)parts[1] != "") // Loads a specific test from within the currently loaded suite
    {
        if(_currentSuite)
        {
            string name = llDumpList2String(llList2List(parts, 1, -1), " ");
            integer loadedTest = llListFindList(_tests, [name]);
            if(loadedTest)
            {
                _tests = [name];
                log("Setting only test to be run to be \"" + name + "\". To restore run " + DEFER_STR(/COMMAND_CHANNEL COMMAND_LOAD) + " " + _currentSuite);
            }
            else
            {
                log("Test \"" + name + "\" was not found in loaded tests for suite \"" + _currentSuite + "\".");     
                logVerbose("Available tests: " + llDumpList2String(_tests, ", "));
            }
        }
        else
            log(DEFER_STR(There is no suite selected. Run the following command to load a test suite: DEFER_STR(/COMMAND_CHANNEL COMMAND_LOAD <name>)));
    }
    else if(cmd == DEFER_STR(COMMAND_START)) // Starts the currently loaded test suite
    {
        if(_currentSuite)
        {
            log("Starting test suite.");
            llLinksetDataDeleteFound("^R_.*$", _);
            if(TRUE) state load_next_test;
        }
        else
            log(DEFER_STR(There is no suite selected. Run the following command to load a test suite: DEFER_STR(/COMMAND_CHANNEL COMMAND_LOAD <name>)));
    }
    else if(cmd == DEFER_STR(COMMAND_SUITES)) // Dumps a list of all currently loaded test suites from notecards
    {
        list suites = llLinksetDataFindKeys("^NC_.*$", 0, 0);
        if(suites)
        {
            log("Test suites available:");
            integer i;
            integer len = llGetListLength(suites);
            string json;
            for(i = 0; i < len; i++)
            {
                json = llLinksetDataRead((string)suites[i]);
                log("    [" + llGetSubString((string)suites[i], 3, -1) + "] " + llJsonGetValue(json, ["name"]) + " (v" + llJsonGetValue(json, ["version"]) +")");
            }
        }
        else
            log(DEFER_STR(No suites found in LSD. Insert notecards with test data and use: DEFER_STR(/COMMAND_CHANNEL COMMAND_RELOAD)));
    }
    else if(cmd == DEFER_STR(COMMAND_MEM)) // Dumps info about current memory usage
    {
        integer memused = llGetUsedMemory();
        integer memmax = llGetMemoryLimit();
        integer memfree = llGetFreeMemory();
        integer memperc = (integer)(100.0 * (float)memused/memmax);
        integer lsdAvailable = llLinksetDataAvailable();

        log("Memory Used: " + (string)memused + "\nMemory Free: " + (string)memfree + "\nMemory Limit: " + (string)memmax + "\nPercentage of Memory Usage: " + (string)memperc + "%.");
        log("LSD available: " + (string)lsdAvailable + " / 131072 (" + (string)((integer)(100 * (float)lsdAvailable/131072)) + "%).");
    }
    else if(cmd == DEFER_STR(COMMAND_REPORT)) // Reports on test results, if present
    {
        list testResultData = llLinksetDataFindKeys("^R_.*$", 0, 0);
        integer i;
        integer len = llGetListLength(testResultData);
        if(len == 0)
        {
            log("There are no test results available.");
            return;
        }
        for(i = 0; i < len; i++)
        {
            string testResult = llLinksetDataRead((string)testResultData[i]);
            log("Test result for \"" + llJsonGetValue(testResult, ["name"]) + "\": " + llJsonGetValue(testResult, ["result"]));
#ifndef VERBOSE
            if(llJsonGetValue(testResult, ["result"]) == "Failure") {
#endif
            log("Task results:");
            list taskResults = llJson2List(llJsonGetValue(testResult, ["actions"]));
            integer j;
            integer taskLen = llGetListLength(taskResults);
            for(j = 0; j < taskLen; j++)
            {
                string taskResult = (string)taskResults[j];
                string name = llJsonGetValue(taskResult, ["name"]);
                string result = llJsonGetValue(taskResult, ["result"]);
                if(result == "Failure")
                    log("  \"" + name + "\": " + result + ". Reason: " + llJsonGetValue(taskResult, ["message"]) + ".");
                else
                    log("  \"" + name + "\": " + result + ".");
            }
#ifndef VERBOSE
            }
#endif
        }
    }
    else if(cmd == DEFER_STR(COMMAND_RESET))
        llResetScript();
}

// States

default
{
    state_entry()
    {
        killOtherScripts();

        logInfo("Wiping LSD.");
        llLinksetDataReset();

#if ASSERT_SEND_METHOD == ASSERT_SEND_METHOD_PH
        llListen(TEST_CHANNEL, _, NULL_KEY, _);
#endif
        loadNotecards();
        llListen(COMMAND_CHANNEL, _, llGetOwner(), _);
    }

    dataserver(key queryid, string data)
    {
        integer i;
        integer len = llGetListLength(_tests);
        for(i = 0; i < len; i++)
        {
            list parts = llParseString2List((string)_tests[i], [":"], []);
            if((key)parts[1] == queryid)
            {
                integer lineIndex = (integer)parts[2];
                string name = (string)parts[0];
                string notecardTestData = llLinksetDataRead("NC_" + name);
                while (data != EOF && data != NAK) {
                    if(data != "")
                    {
                        data = llStringTrim(data, STRING_TRIM);
                        notecardTestData += data;
                    }
                    data = llGetNotecardLineSync((string)parts[0], ++lineIndex);
                }

                if (data == NAK)
                {
                    llLinksetDataWrite("NC_" + name, notecardTestData);
                    string _queryId = (string)llGetNotecardLine((string)parts[0], (integer)parts[2]);
                    _tests = llListReplaceList(_tests, [name + ":" + _queryId + ":" + (string)lineIndex], i, i);
                }

                if (data == EOF)
                {
                    llLinksetDataWrite("NC_" + name, notecardTestData);
                    //llLinksetDataDelete("NC_" + name);
                    if(llJsonValueType(notecardTestData, []) == JSON_INVALID)
                    {
                        log("Notecard \"" + name + "\" does not contain valid JSON.");
                        llLinksetDataDelete("NC_" + name);
                    }
                    else
                        log("Notecard \"" + name + DEFER_STR(" loaded. Activate it's suite using "/COMMAND_CHANNEL load) + " " + name + "\"");
                    
                    _tests = llDeleteSubList(_tests, i, i);
                }

                return;
            }
        }
    }

    listen(integer channel, string name, key id, string message)
    {
#if ASSERT_SEND_METHOD == ASSERT_SEND_METHOD_PH
        if(channel == TEST_CHANNEL)
        {
            if(message == "asserttype chat")
                _assertSendType = ASSERT_SEND_METHOD_CHAT;
            else if(message == "asserttype link")
                _assertSendType = ASSERT_SEND_METHOD_LINK;
            return;
        }
#endif
        commandHandler(message);
    }

    on_rez(integer start_param)
    {
        llResetScript();
    }
}

state report
{
    state_entry()
    {
        log(DEFER_STR(Testsuite has finished. Use DEFER_STR(/COMMAND_CHANNEL report) to show the test results, or DEFER_STR(/COMMAND_CHANNEL reset) to reset.));
        llListen(COMMAND_CHANNEL, _, llGetOwner(), _);
    }

    listen(integer channel, string name, key id, string message)
    {
        commandHandler(message);
    }

    on_rez(integer start_param)
    {
        llResetScript();
    }
}

state load_next_test
{
    on_rez(integer start_param)
    {
        llResetScript();
    }

    state_entry()
    {
        @advanceTest;

        _activeTest++;

        if(_activeTest >= llGetListLength(_tests))
        {
            _activeTestState = TESTSTATE_IDLE;
            state report;
        }
        else
        {
            string testName = (string)_tests[_activeTest];
            logVerbose("Loading data for test: \"" + testName + "\".");
            string testJson = llLinksetDataRead("T_" + testName);
            list dependencies = llJson2List(llJsonGetValue(testJson, ["dependencies"]));
            list actions = getTaskActions();
            logVerbose("Dependencies: " + llDumpList2String(dependencies, ", "));
            if(dependencies)
            {
                integer i;
                integer len = llGetListLength(dependencies);
                for(i = 0; i < len; i++)
                {
                    string dependencyTestResult = llLinksetDataRead("R_" + (string)dependencies[i]);
                    if(llJsonGetValue(dependencyTestResult, ["result"]) != "Success")
                    {
                        string testResult = llJsonSetValue("{}", ["name"], (string)_tests[_activeTest]);
                        testResult = llJsonSetValue(testResult, ["result"], "Skipped - Dependencies not met");
                        len = llGetListLength(actions);
                        for(i = 0; i < len; i++)
                        {
                            string taskResult = "{}";
                            taskResult = llJsonSetValue(taskResult, ["name"], llJsonGetValue((string)actions[i], ["name"]));
                            taskResult = llJsonSetValue(taskResult, ["actionType"], llJsonGetValue((string)actions[i], ["actionType"]));
                            taskResult = llJsonSetValue(taskResult, ["result"], "Not run");

                            testResult = llJsonSetValue(testResult, ["actions", JSON_APPEND], taskResult);
                        }

                        llLinksetDataWrite("R_" + (string)_tests[_activeTest], testResult);
                        logInfo("Skipping test \"" + testName + "\" because dependencies are not met.");
                        jump advanceTest;
                    }
                }
            }

            logInfo("Test loaded. " + (string)llGetListLength(actions) + " actions to perform.");
            state run_test;
        }
    }
}

state run_test
{
    on_rez(integer start_param)
    {
        llResetScript();
    }

    state_entry()
    {
        _activeTestState = TESTSTATE_IDLE;
        _currentTaskState = TASKSTATE_IDLE;

        logVerbose("Initializing test.");
        _activeTestState = TESTSTATE_INITIALIZING;
        llListen(TEST_CHANNEL, _, NULL_KEY, _);
        llListen(COMMAND_CHANNEL, _, llGetOwner(), _);

        integer i;
        list actions = getTaskActions();

        for(i = 0; i < llGetListLength(actions); i++)
        {
            string task = llList2String(actions, i);
            if ((integer)llJsonGetValue(task, ["actionType"]) == ACTION_EXPECT)
            {
                list taskParams = llJson2List(llJsonGetValue(task, ["parameters"]));
                string channel = getParameter((string)taskParams[0]);
                llListen((integer)channel, _, NULL_KEY, _);
            }
        }

        logVerbose("Finished initialization. Starting execution of actions.");

        _activeTestState = TESTSTATE_RUNNING;
        loadNextTask();
        llSetTimerEvent(0.1);
        llResetTime();
    }

    state_exit()
    {
        integer i;
        integer len;
        if(_rezzedDummies)
        {
            len = llGetListLength(_rezzedDummies);
            for(i = 0; i < len; i++)
            {
                list parts = llParseString2List((string)_rezzedDummies[i], [":"], []);
                llRegionSayTo((key)parts[1], TEST_CHANNEL, RELAY_COMMAND_DIE);
                llLinksetDataDelete((string)parts[0]);
            }
            
            _rezzedDummies = [];
        }

        list actions = getTaskActions();

        string testName = (string)_tests[_activeTest];
        string testResult = llJsonSetValue("{}", ["name"], testName);
        string taskResult;
        if(_activeTestState == TESTSTATE_SUCCESS)        
            testResult = llJsonSetValue(testResult, ["result"], "Success");
        else if(_activeTestState == TESTSTATE_CANCELLED)
            testResult = llJsonSetValue(testResult, ["result"], "Cancelled");
        else
            testResult = llJsonSetValue(testResult, ["result"], "Failure");

        len = llGetListLength(actions);
        for(i = 0; i < len; i++)
        {
            taskResult = "{}";
            taskResult = llJsonSetValue(taskResult, ["name"], llJsonGetValue((string)actions[i], ["name"]));
            taskResult = llJsonSetValue(taskResult, ["actionType"], llJsonGetValue((string)actions[i], ["actionType"]));
            if(i == _currentTask && _activeTestState == TESTSTATE_FAILURE)
            {
                taskResult = llJsonSetValue(taskResult, ["result"], "Failure");
                taskResult = llJsonSetValue(taskResult, ["message"], _currentTaskFailureMessage);
            }
            else if(i > _currentTask  && _activeTestState == TESTSTATE_FAILURE)
                taskResult = llJsonSetValue(taskResult, ["result"], "Not run");
            else
                taskResult = llJsonSetValue(taskResult, ["result"], "Success");

            testResult = llJsonSetValue(testResult, ["actions", JSON_APPEND], taskResult);
        }

        llLinksetDataWrite("R_" + testName, testResult);

        _receivedMessage = [];

        _currentTaskData = "";
        _currentTaskFailureMessage = "";
        _currentTask = 0;

        _assertToken = NULL_KEY;

        _rezTime = 0;
        _askTime = 0;
        _relayTime = 0;
        _sendTime = 0;
        _assertTime = 0;
    }

    listen(integer channel, string name, key id, string message)
    {
        logListener(message, channel, llGetTime());
        if(channel == TEST_CHANNEL)
        {
            integer currentAction = (integer)llJsonGetValue(_currentTaskData, ["actionType"]);
            if(currentAction == ACTION_ASK)
            {
                if(message == ASK_YES)
                    _currentTaskState = TASKSTATE_SUCCESS;
                else if(message == ASK_NO)
                    _currentTaskState = TASKSTATE_FAILURE;

                logVerbose("ASK result: Got \"" + message + "\".");
                return;
            }
            else if(currentAction == ACTION_ATTACH)
            {
                saveRezzedDummy(id);
                return;
            }
            else if(currentAction == ACTION_ASSERT)
            {
                // assert 7321d897-ad5f-f98c-11ea-f5a56e2399ff ok
                string cmd = llGetSubString(message, 0, 5);
                if(cmd == ASSERT_REPLY)
                {
                    key token = (key)llGetSubString(message, 7, 42);
                    if(token != NULL_KEY && token == _assertToken)
                    {
                        string result = llGetSubString(message, 44, -1);
                        if(result == ASSERT_OK)
                            _currentTaskState = TASKSTATE_SUCCESS;
                        if(result == ASSERT_FAIL)
                            _currentTaskState = TASKSTATE_FAILURE;
                    }                
                
                    logVerbose("ASSERT result: Got \"" + message + "\".");
                    return;
                }
            }
        }
        else if(channel == COMMAND_CHANNEL)
        {
            if(message == DEFER_STR(COMMAND_STOP))
            {
                _activeTest = llGetListLength(_tests);
                _currentTaskState = TASKSTATE_FAILURE;
                _activeTestState = TESTSTATE_CANCELLED;
                llSetTimerEvent(0);
            }
        }

        _receivedMessage += [message, channel, llGetTime()];
    }

    object_rez(key id)
    {
        if((integer)llJsonGetValue(_currentTaskData, ["actionType"]) == ACTION_REZ) // ATTACH will send a message when it attaches
            saveRezzedDummy(id);
        else
            llRegionSayTo(id, TEST_CHANNEL, RELAY_COMMAND_ATTACH + " " + (string)DUMMY_ATTACH_POINT);
    }

    timer()
    {
        if(_activeTestState == TESTSTATE_SUCCESS || _activeTestState == TESTSTATE_FAILURE)
            state load_next_test;

        if(_currentTaskState == TASKSTATE_IDLE)
        {
            list placeholderChecks = [];
            list params = llJson2List(llJsonGetValue(_currentTaskData, ["parameters"]));

            // Get parameters and replace placeholders, check if placeholder subsitution was succesful and if not fail the test
            _currentActionParam1 = getParameter((string)params[0]);
            if(_currentActionParam1 == INVALID_PLACEHOLDER)
            {
                logInfo("Placeholder in p1 is invalid.");
                placeholderChecks += [(string)params[0]];            
            }
            _currentActionParam2 = getParameter((string)params[1]);
            if(_currentActionParam2 == INVALID_PLACEHOLDER)
            {
                logInfo("Placeholder in p2 is invalid.");
                placeholderChecks += [(string)params[1]];
            }
            _currentActionParam3 = getParameter((string)params[2]);
            if(_currentActionParam3 == INVALID_PLACEHOLDER)
            {
                logInfo("Placeholder in p3 is invalid.");
                placeholderChecks += [(string)params[2]];
            }
            _currentActionParam4 = getParameter((string)params[3]);
            if(_currentActionParam4 == INVALID_PLACEHOLDER)
            {
                logInfo("Placeholder in p4 is invalid.");
                placeholderChecks += [(string)params[3]];
            }
            _currentActionParam5 = getParameter((string)params[4]);
            if(_currentActionParam4 == INVALID_PLACEHOLDER)
            {
                logInfo("Placeholder in p5 is invalid.");
                placeholderChecks += [(string)params[4]];
            }

            logVerbose("Parameters: p1: \"" + _currentActionParam1 + "\" p2: \"" + _currentActionParam2 + "\" p3: \"" + _currentActionParam3 + "\" p4: \"" + _currentActionParam4 + "\" p5: \"" + _currentActionParam5 + "\"");
            if(placeholderChecks)
            {
                logInfo("There was a problem with a placeholder.");
                _currentTaskState = TASKSTATE_FAILURE;
                if(llGetListLength(placeholderChecks) > 1)
                    _currentTaskFailureMessage = "Placeholders were not found in LSD: " + llDumpList2String(placeholderChecks, ", ");
                else
                    _currentTaskFailureMessage = "Placeholder not found in LSD: " + (string)placeholderChecks[0];
            }
        }

        integer currentActionType = (integer)llJsonGetValue(_currentTaskData, ["actionType"]);
        if(currentActionType == ACTION_REZ || currentActionType == ACTION_ATTACH)
        {
            if(_currentTaskState == TASKSTATE_IDLE)
            {
                if(llLinksetDataRead(_currentActionParam1))
                {
                    logInfo("Unable to rez with name \"" + _currentActionParam1 + "\" as a placeholder with that name already exists.");
                    _currentTaskFailureMessage = "Placeholder with name \"" + _currentActionParam1 + "\" already exists.";
                    _currentTaskState = TASKSTATE_FAILURE;
                }
                else
                {
                    if(currentActionType == ACTION_REZ)
                    {
                        vector myPos = llGetPos();
                        vector forwardOffset = <(float)_currentActionParam2, 0.0, 0.0>; // Place the rezzed object x meters away based on the parameters of REZ
                        vector targetPos = myPos + (forwardOffset * llGetRot());

                        list ray = llCastRay(targetPos + <0,0,1>, targetPos - <0,0,4>, [RC_REJECT_TYPES, RC_REJECT_AGENTS]);
                        
                        if (llList2Integer(ray, -1) > 0) // Try and find the floor
                            targetPos = llList2Vector(ray, 1); 
                        else // Fallback to terrain
                            targetPos.z = llGround(targetPos - myPos); 

                        targetPos.z += DUMMY_OBJECT_HEIGHT / 2; // Fix the height of the rezzed object

                        rotation correction = llEuler2Rot(DUMMY_OBJECT_ROTATION * DEG_TO_RAD); // Fix the rotation of the rezzed object
                        vector rotEuler = llRot2Euler(llGetRot());
                        rotation flatRot = llEuler2Rot(<0.0, 0.0, rotEuler.z>);

                        llRezObject(DUMMY_OBJECT, targetPos, ZERO_VECTOR, correction * flatRot, TEST_CHANNEL);
                    }
                    else if(currentActionType == ACTION_ATTACH)
                        llRezObject(DUMMY_ATTACH, llGetPos() + <1,0,0>, ZERO_VECTOR, ZERO_ROTATION, TEST_CHANNEL);

                    _rezTime = llGetTime();
                    _currentTaskState = TASKSTATE_WAITING;
                }
            }
            else if(_currentTaskState == TASKSTATE_WAITING)
            {
                if(llGetTime() - _rezTime > 10.0)
                {
                    logInfo("Didn't get a rez event yet, did the rez/attach fail?");
                    _currentTaskFailureMessage = "No rez event raised";
                    _currentTaskState = TASKSTATE_FAILURE;
                }
            }
        }
        else if(currentActionType == ACTION_ASK)
        {
            if(_currentTaskState == TASKSTATE_IDLE)
            {
#if ASK_TYPE == ASK_TYPE_CHAT
                llOwnerSay(_currentActionParam1 + " [secondlife:///app/chat/" + (string)TEST_CHANNEL + "/" + ASK_YES + " " + ASK_YES + "] or [secondlife:///app/chat/" + (string)TEST_CHANNEL + "/" + ASK_NO + " " + ASK_NO + "]");
#elif ASK_TYPE == ASK_TYPE_DIALOG
                llDialog(llGetOwner(), _currentActionParam1, [ASK_YES, ASK_NO], TEST_CHANNEL);
#else
#error "Invalid configuration for ASK_TYPE"
#endif
                _askTime = llGetTime();
                _currentTaskState = TASKSTATE_WAITING;
            }
            else if(_currentTaskState == TASKSTATE_WAITING)
            {
                if(llGetTime() - _askTime > 10.0)
                {
                    logInfo("Did not get a reply from user within 10 seconds.");
                    _currentTaskFailureMessage = "No reply from user";
                    _currentTaskState = TASKSTATE_FAILURE;
                }
            }
        }
        else if(currentActionType == ACTION_SEND)
        {
            if(_currentTaskState == TASKSTATE_IDLE)
            {
                if((key)_currentActionParam1 == NULL_KEY)
                {
                    _currentTaskState = TASKSTATE_FAILURE;
                    _currentTaskFailureMessage = "Target key was NULL_KEY.";
                }
                else
                {
                    logVerbose("Sending: \"" + _currentActionParam3 + "\" on channel: \"" + _currentActionParam2 + "\"");

                    llRegionSayTo((key)_currentActionParam1, (integer)_currentActionParam2, _currentActionParam3);
                    _sendTime = llGetTime();
                    _currentTaskState = TASKSTATE_SUCCESS;
                }
            }
        }
        else if(currentActionType == ACTION_RELAY)
        {
            if(_currentTaskState == TASKSTATE_IDLE)
            {
                if((key)_currentActionParam1 == NULL_KEY)
                {
                    _currentTaskState = TASKSTATE_FAILURE;
                    _currentTaskFailureMessage = "Target key was NULL_KEY.";
                }
                else if((integer)_currentActionParam4 != RELAY_TYPE_REGIONSAYTO && (integer)_currentActionParam4 != RELAY_TYPE_SAY && (integer)_currentActionParam4 != RELAY_TYPE_WHISPER && (integer)_currentActionParam4 != RELAY_TYPE_SHOUT)
                {
                    _currentTaskState = TASKSTATE_FAILURE;
                    _currentTaskFailureMessage = "Invalid value type \"" + _currentActionParam4 + "\" specified.";
                    return;
                }
                else
                {
                    logVerbose("Sending message of type: " + _currentActionParam4 + " to be send on channel: " + _currentActionParam2 + " message: " + _currentActionParam3);
                    llRegionSayTo((key)_currentActionParam1, TEST_CHANNEL, RELAY_COMMAND_RELAY + " " + _currentActionParam4 + " " + _currentActionParam2 + " " + _currentActionParam3);
                    _relayTime = llGetTime();
                    _currentTaskState = TASKSTATE_SUCCESS;
                }
            }
        }
        else if(currentActionType == ACTION_EXPECT)
        {
            if(_currentTaskState == TASKSTATE_IDLE)
            {
                if((integer)_currentActionParam4 == EXPECT_TYPE_SEND)
                    _timeToCheck = _sendTime;
                else if((integer)_currentActionParam4 == EXPECT_TYPE_RELAY)
                    _timeToCheck = _relayTime;

                _expectLastMessageIndex = 0;
                _currentTaskState = TASKSTATE_WAITING;
            }
            if(_currentTaskState == TASKSTATE_WAITING)
            {
                integer len = llGetListLength(_receivedMessage);
                logVerbose("Received messages at this point: " + llDumpList2String(_receivedMessage, ", "));
                string compare = _currentActionParam2;
                integer wildcardIndex = llSubStringIndex(compare, "*");
                if(wildcardIndex != -1)
                    compare = llGetSubString(compare, 0, wildcardIndex - 1);
                for(; _expectLastMessageIndex < len; _expectLastMessageIndex += 3)
                {
                    if((float)_receivedMessage[_expectLastMessageIndex + 2] > _timeToCheck)
                    {
                        if((integer)_receivedMessage[_expectLastMessageIndex + 1] == (integer)_currentActionParam1)
                        {
                            string message = (string)_receivedMessage[_expectLastMessageIndex];
                            if(wildcardIndex != -1)
                                message = llGetSubString(message, 0, wildcardIndex - 1);
                            logVerbose("Current string comparison: " + message + " to compare it to: " + compare);
                            if(message == compare)
                            {
                                if(_currentActionParam5)
                                {
                                    _currentTaskFailureMessage = "Found \"" + _currentActionParam2 + "\" among messages received.";
                                    _currentTaskState = TASKSTATE_FAILURE;
                                    jump endfor;
                                }
                                else
                                {
                                    _currentTaskState = TASKSTATE_SUCCESS;
                                    jump endfor;
                                }
                            }
                        }
                    }
                }
                @endfor;

                if(_currentTaskState == TASKSTATE_WAITING)
                {
                    if(llGetTime() > (_timeToCheck + ((float)_currentActionParam3 / 1000)))
                    {
                        if(_currentActionParam5)                        
                            _currentTaskState = TASKSTATE_SUCCESS;
                        else
                        {
                            _currentTaskFailureMessage = "Unable to find \"" + _currentActionParam2 + "\" among messages received.";
                            _currentTaskState = TASKSTATE_FAILURE;
                        }
                    }
                }
            }
        }
        else if(currentActionType == ACTION_ASSERT)
        {
            if(_currentTaskState == TASKSTATE_IDLE)
            {
                if(_assertTime == 0 && (integer)_currentActionParam1 != 0)
                    _assertTime = llGetTime();

                if((integer)_currentActionParam3 == ASSERT_TYPE_SEND)
                    _timeToCheck = _sendTime;
                else if((integer)_currentActionParam3 == ASSERT_TYPE_RELAY)
                    _timeToCheck = _relayTime;

                _currentTaskState = TASKSTATE_WAITING;
            }
            
            if(_currentTaskState == TASKSTATE_WAITING)
            {
                if(_assertToken)
                {
                    if(llGetTime() > (_assertTime + ((float)ASSERT_REPLY_TIMEOUT / 1000)))
                    {
                        _currentTaskFailureMessage = "Did not receive a reply in time from the PH script.";
                        _currentTaskState = TASKSTATE_FAILURE;
                    }
                }
                else
                {
                    if(llGetTime() > (_assertTime + ((float)_currentActionParam1 / 1000)))
                    {
                        string json = "{}";
                        _assertToken = llGenerateKey();
                        json = llJsonSetValue(json, ["token"], _assertToken);
                        json = llJsonSetValue(json, ["test"], (string)_tests[_activeTest]);
                        json = llJsonSetValue(json, ["task"], llJsonGetValue(_currentTaskData, ["name"]));

                        integer i;
                        integer len = llGetListLength(_receivedMessage);
                        string msgJson;
                        for(i = 0; i < len; i += 3)
                        {
                            msgJson = "{}";
                            if((float)_receivedMessage[i + 2] > _timeToCheck)
                            {
                                if((integer)_receivedMessage[i + 1] == (integer)_currentActionParam2)
                                {
                                    msgJson = llJsonSetValue(msgJson, ["m"], (string)_receivedMessage[i]);                                
                                    msgJson = llJsonSetValue(msgJson, ["t"], (string)_receivedMessage[i + 2]);

                                    json = llJsonSetValue(json, ["msgs", JSON_APPEND], msgJson);
                                }
                            }
                        }
                        logInfo("Sending JSON message to PH script.");
                        logVerbose("JSON: " + json);
#if ASSERT_SEND_METHOD == ASSERT_SEND_METHOD_PH
                        if(_assertSendType == ASSERT_SEND_METHOD_CHAT)
#endif
#if ASSERT_SEND_METHOD == ASSERT_SEND_METHOD_CHAT || ASSERT_SEND_METHOD == ASSERT_SEND_METHOD_PH
                        llRegionSayTo(llGetOwner(), TEST_CHANNEL, json);
#endif
#if ASSERT_SEND_METHOD == ASSERT_SEND_METHOD_PH
                        if(_assertSendType == ASSERT_SEND_METHOD_LINK)
#endif
#if ASSERT_SEND_METHOD == ASSERT_SEND_METHOD_LINK || ASSERT_SEND_METHOD == ASSERT_SEND_METHOD_PH
                        llMessageLinked(LINK_THIS, 0, json, NULL_KEY);
#endif
                        _assertTime = llGetTime();
                    }
                }
            }
        }

        if(_currentTaskState == TASKSTATE_FAILURE)
        {
            reportTaskState();
            state load_next_test;
        }
        else if(_currentTaskState == TASKSTATE_SUCCESS)
            loadNextTask();
    }
}