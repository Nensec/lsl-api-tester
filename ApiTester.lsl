// ####################################################################################
// -- Changelog, tester information, readme, and instructions to create a new tester --
// ####################################################################################

// V's Tester v1.1, by Voisin (Nensec Resident)

// Latest version can always be found on github: https://github.com/Nensec/lsl-api-tester
// Feel free to modify and redistribute this script however you please, I simply ask that you keep my name as the original author by keeping the changelog intact and simply add your own changelog.

// -- Changelog

// v1.0: Initial version - Voisin (Nensec Resident)
// v1.1: Removed Boost framework and made tester completely notecard based, removing the need for a runner script - Voisin (Nensec Resident)

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

// -- Defining tests

// Test are loaded via notecard and are formatted in JSON. You can write them in your IDE of choice that allows for JSON syntax validation and then simply copy over the text into the notecard.
// There is a schema available in the repository, you can point your test suite towards it to validate it to what the tester expects.
// Simply add:
// { "$schema": "https://raw.githubusercontent.com/Nensec/lsl-api-tester/refs/heads/master/test-suite.schema.json" }

// Note: This schema is ignored by the tester when parsing in-game, you can leave it in your notecard.

// -- Common actions

// Define common functions that are required in many tests, this helps reducing the repetitiveness and ensure that you are generally doing the same thing.

// For example: Your API requires a script to announce itself first before it will accept a command from the script, rather than writing the full SEND to authenticate as part of the test data simply define it once there and use it in place of an action.

// - Available actions:

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
// Turning off logging will help a lot in script memory, it is recommended to only turn on logging when you are experiencing problems and when you do turn off irrelevant tests by commenting them out.
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

#define COMMAND_LOAD load
#define COMMAND_RELOAD reload
#define COMMAND_START start
#define COMMAND_SUITES suites
#define COMMAND_MEM mem
#define COMMAND_STOP stop

#define INVALID_PLACEHOLDER JSON_INVALID

#define DEFAULT_PLACEHOLDERS \
        llLinksetDataWrite("AV", llGetOwner()); \
        llLinksetDataWrite("TESTCHANNEL", (string)TEST_CHANNEL);

#define COMMON_ACTIONS \
        llLinksetDataWrite("C_REZ_DUMMY", DEFER_STR({"n":"Rez dummy","a":ACTION_REZ,"p":["DUMMY",2.5]})); \
        llLinksetDataWrite("C_ATTACH_DUMMY", DEFER_STR({"n":"Attach dummy","a":ACTION_ATTACH,"p":["ATTACH"]}));

// -- Global variables

string _currentSuite;
list _tests = []; // Currently loaded test suite

integer _activeTest = -1; // Index of current test
integer _activeTestState = TESTSTATE_IDLE; // Current state of the test

integer _currentTask = 0; // The current task
string _currentTaskData; // JSON data of current task
integer _currentTaskState = TESTSTATE_IDLE; // Current state of the current task
string _currentTaskFailureMessage;

list _receivedMessage = []; // Strided list of 3: [message, channel, timestamp]
list _rezzedDummies = []; // All of the dummies rezzed during the current test

// Parameters are global, this is to lower memory fragmentation
string  _p1; // Parameter 1 of current action
string  _p2; // Parameter 2 of current action
string  _p3; // Parameter 3 of current action
string  _p4; // Parameter 4 of current action

float _rezTime; // When was the last REZ
float _sendTime; // When was the last SEND
float _relayTime; // when was the last RELAY
float _askTime; // when was the last ASK

float _touchTime; // When was the tester last touched

list _notecardQueries = []; // active notecard queries

// -- Helper functions

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

        logInfo("Next task is: " + llJsonGetValue(_currentTaskData, ["n"]));
    }
}

list getTaskActions()
{
    list actions = llJson2List(llJsonGetValue(llLinksetDataRead("T_" + (string)_tests[_activeTest]), ["a"]));
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
    _notecardQueries = [];
    _currentSuite = _;

    llLinksetDataDeleteFound("NC_", _);

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
        _notecardQueries += [name + ":" + queryId + ":0"];
        logVerbose("Parsing notecard: \"" + name + "\".");
    }
}

saveRezzedDummy(key id)
{
    logVerbose("Saving placeholder \"" + _p1 + "\" with value: \"" + (string)id + "\".");
    llLinksetDataWrite(_p1, id); // Save the rezzed object in LSD so it can be used as a placeholder
    llRegionSayTo(id, TEST_CHANNEL, RELAY_COMMAND_INIT + " " + _p1);
    _rezzedDummies += [_p1 + ":" + (string)id];
    _currentTaskState = TASKSTATE_SUCCESS;
}

killOtherScripts()
{
    integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
    string name;
    while(count--) // Kill other scripts in the tester
    {
        name = llGetInventoryName(INVENTORY_SCRIPT, count);
        if(name != llGetScriptName())
            llSetScriptState(name, FALSE);
    }
}

commandHandler(string message)
{
    list parts = llParseString2List(message, [" "], []);
    string cmd = (string)parts[0];
    if(cmd == DEFER_STR(COMMAND_RELOAD))
        loadNotecards();
    else if(cmd == DEFER_STR(COMMAND_LOAD) && (string)parts[1] != "")
    {
        string name = (string)parts[1];
        string json = llLinksetDataRead("NC_" + name);
        if(llJsonValueType(json, []) != JSON_OBJECT)
            log("There is no suite called \"" + name + "\"" + DEFER_STR(View available suites using DEFER_STR(/COMMAND_CHANNEL COMMAND_SUITES)));
        else
        {
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
    else if(cmd == DEFER_STR(COMMAND_START))
    {
        if(_currentSuite)
        {
            log("Starting test suite.");
            if(TRUE) state load_next_test;
        }
        else
            log(DEFER_STR(There is no suite selected. Run the following command to load a test suite: DEFER_STR(/COMMAND_CHANNEL COMMAND_LOAD <name>)));
    }
    else if(cmd == DEFER_STR(COMMAND_SUITES))
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
    else if(cmd == DEFER_STR(COMMAND_MEM))
    {
        integer memused = llGetUsedMemory();
        integer memmax = llGetMemoryLimit();
        integer memfree = llGetFreeMemory();
        integer memperc = (integer)(100.0 * (float)memused/memmax);
        integer lsdAvailable = llLinksetDataAvailable();

        log("Memory Used: " + (string)memused + "\nMemory Free: " + (string)memfree + "\nMemory Limit: " + (string)memmax + "\nPercentage of Memory Usage: " + (string)memperc + "%.");
        log("LSD available: " + (string)lsdAvailable + " / 131072 (" + (string)((integer)(100 * (float)lsdAvailable/131072)) + "%).");
    }
}

// -- States

default
{
    state_entry()
    {
        killOtherScripts();

        logInfo("Wiping LSD.");
        llLinksetDataReset();

        logVerbose("Loading placeholders into LSD..");
        DEFAULT_PLACEHOLDERS
        logVerbose("Loading common actions into LSD..");
        COMMON_ACTIONS
#ifdef VERBOSE
        logVerbose("Data saved in LSD:");
        list keys = llLinksetDataListKeys(0, 0);
        for(;keys;keys=llDeleteSubList(keys,0,0))
            llOwnerSay("    " + (string)keys[0] + ": " + llLinksetDataRead((string)keys[0]));
#endif
        loadNotecards();

        llListen(COMMAND_CHANNEL, _, llGetOwner(), _);
    }

    dataserver(key queryid, string data)
    {
        integer i;
        integer len = llGetListLength(_notecardQueries);
        for(i = 0; i < len; i++)
        {
            list parts = llParseString2List((string)_notecardQueries[i], [":"], []);
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
                    _notecardQueries = llListReplaceList(_notecardQueries, [name + ":" + _queryId + ":" + (string)lineIndex], i, i);
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
                    
                    _notecardQueries = llDeleteSubList(_notecardQueries, i, i);
                }

                return;
            }
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        commandHandler(message);
    }

    touch_start(integer num_detected)
    {
        if(_currentSuite)
        {
            log("Starting test suite.");
            state load_next_test;
        }
        else
            log(DEFER_STR(There is no suite selected. Run the following command to load a test suite: DEFER_STR(/COMMAND_CHANNEL load <name>)));
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
        log("Testsuite has finished. Touch me to get the output, or hold for three seconds to reset.");
        llListen(COMMAND_CHANNEL, _, llGetOwner(), _);
    }

    touch_start(integer num_detected)
    {
        _touchTime = llGetTime();
    }

    touch(integer num_detected)
    {
        if(_touchTime != 0 && (_touchTime + 3.0) < llGetTime())
            llResetScript();
    }

    touch_end(integer num_detected)
    {
        _touchTime = 0;
        list testData = llLinksetDataFindKeys("^R_.*$", 0, 0);
        integer i;
        integer len = llGetListLength(testData);
        for(i = 0; i < len; i++)
        {
            string testResult = llLinksetDataRead((string)testData[i]);
            log("Test result for \"" + llJsonGetValue(testResult, ["n"]) + "\": " + llJsonGetValue(testResult, ["r"]));
#ifndef VERBOSE
            if(llJsonGetValue(testResult, ["r"]) == "Failure") {
#endif
            log("Task results:");
            list taskResults = llJson2List(llJsonGetValue(testResult, ["t"]));
            integer j;
            integer taskLen = llGetListLength(taskResults);
            for(j = 0; j < taskLen; j++)
            {
                string taskResult = (string)taskResults[j];
                string name = llJsonGetValue(taskResult, ["n"]);
                string result = llJsonGetValue(taskResult, ["r"]);
                if(result == "Failure")
                    log("  \"" + name + "\": " + result + ". Reason: " + llJsonGetValue(taskResult, ["m"]) + ".");
                else
                    log("  \"" + name + "\": " + result + ".");
            }
#ifndef VERBOSE
            }
#endif
        }
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
            list dependencies = llJson2List(llJsonGetValue(testJson, ["d"]));
            list actions = getTaskActions();
            logVerbose("Dependencies: " + llDumpList2String(dependencies, ", "));
            if(dependencies)
            {
                integer i;
                integer len = llGetListLength(dependencies);
                for(i = 0; i < len; i++)
                {
                    string dependencyTestResult = llLinksetDataRead("R_" + (string)dependencies[i]);
                    if(llJsonGetValue(dependencyTestResult, ["r"]) != "Success")
                    {
                        string testResult = llJsonSetValue("{}", ["n"], (string)_tests[_activeTest]);
                        testResult = llJsonSetValue(testResult, ["r"], "Skipped - Dependencies not met");
                        len = llGetListLength(actions);
                        for(i = 0; i < len; i++)
                        {
                            string taskResult = "{}";
                            taskResult = llJsonSetValue(taskResult, ["n"], llJsonGetValue((string)actions[i], ["n"]));
                            taskResult = llJsonSetValue(taskResult, ["a"], llJsonGetValue((string)actions[i], ["a"]));
                            taskResult = llJsonSetValue(taskResult, ["r"], "Not run");

                            testResult = llJsonSetValue(testResult, ["t", JSON_APPEND], taskResult);
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
            if ((integer)llJsonGetValue(task, ["a"]) == ACTION_EXPECT)
            {
                list taskParams = llJson2List(llJsonGetValue(task, ["p"]));
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
        _receivedMessage = [];

        _currentTaskData = "";
        _currentTaskFailureMessage = "";
        _currentTask = 0;

        _rezTime = 0;
        _askTime = 0;
        _relayTime = 0;
        _sendTime = 0;

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

        string testResult = llJsonSetValue("{}", ["n"], (string)_tests[_activeTest]);
        string taskResult;
        if(_activeTestState == TESTSTATE_SUCCESS)        
            testResult = llJsonSetValue(testResult, ["r"], "Success");
        else
            testResult = llJsonSetValue(testResult, ["r"], "Failure");

        len = llGetListLength(actions);
        for(i = 0; i < len; i++)
        {
            taskResult = "{}";
            taskResult = llJsonSetValue(taskResult, ["n"], llJsonGetValue((string)actions[i], ["n"]));
            taskResult = llJsonSetValue(taskResult, ["a"], llJsonGetValue((string)actions[i], ["a"]));
            if(i == _currentTask && _activeTestState == TESTSTATE_FAILURE)
            {
                taskResult = llJsonSetValue(taskResult, ["r"], "Failure");
                taskResult = llJsonSetValue(taskResult, ["m"], _currentTaskFailureMessage);
            }
            else if(i > _currentTask  && _activeTestState == TESTSTATE_FAILURE)
                taskResult = llJsonSetValue(taskResult, ["r"], "Not run");
            else
                taskResult = llJsonSetValue(taskResult, ["r"], "Success");

            testResult = llJsonSetValue(testResult, ["t", JSON_APPEND], taskResult);
        }

        llLinksetDataWrite("R_" + (string)_tests[_activeTest], testResult);
    }

    listen(integer channel, string name, key id, string message)
    {
        logListener(message, channel, llGetTime());
        if(channel == TEST_CHANNEL)
        {
            if((integer)llJsonGetValue(_currentTaskData, ["a"]) == ACTION_ASK)
            {
                if(message == ASK_YES)
                    _currentTaskState = TASKSTATE_SUCCESS;
                else if(message == ASK_NO)
                    _currentTaskState = TASKSTATE_FAILURE;

                logVerbose("ASK result: Got \"" + message + "\".");
                return;
            }
            else if((integer)llJsonGetValue(_currentTaskData, ["a"]) == ACTION_ATTACH)
            {
                saveRezzedDummy(id);
                return;
            }
        }
        else if(channel == COMMAND_CHANNEL)
        {
            if(message == DEFER_STR(COMMAND_STOP))
            {
                _activeTest = llGetListLength(_tests);
                _currentTaskState = TASKSTATE_FAILURE;
            }
        }

        _receivedMessage += [message, channel, llGetTime()];
    }

    object_rez(key id)
    {
        if((integer)llJsonGetValue(_currentTaskData, ["a"]) == ACTION_REZ) // ATTACH will send a message when it attaches
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
            list params = llJson2List(llJsonGetValue(_currentTaskData, ["p"]));

            // Get parameters and replace placeholders, check if placeholder subsitution was succesful and if not fail the test
            _p1 = getParameter((string)params[0]);
            if(_p1 == INVALID_PLACEHOLDER)
            {
                logInfo("Placeholder in p1 is invalid.");
                placeholderChecks += [(string)params[0]];            
            }
            _p2 = getParameter((string)params[1]);
            if(_p2 == INVALID_PLACEHOLDER)
            {
                logInfo("Placeholder in p2 is invalid.");
                placeholderChecks += [(string)params[1]];
            }
            _p3 = getParameter((string)params[2]);
            if(_p3 == INVALID_PLACEHOLDER)
            {
                logInfo("Placeholder in p3 is invalid.");
                placeholderChecks += [(string)params[2]];
            }
            _p4 = getParameter((string)params[3]);
            if(_p4 == INVALID_PLACEHOLDER)
            {
                logInfo("Placeholder in p4 is invalid.");
                placeholderChecks += [(string)params[3]];
            }

            logVerbose("Parameters: p1: \"" + _p1 + "\" p2: \"" + _p2 + "\" p3: \"" + _p3 + "\" p4: \"" + _p4 + "\"");
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

        integer currentActionType = (integer)llJsonGetValue(_currentTaskData, ["a"]);
        if(currentActionType == ACTION_REZ || currentActionType == ACTION_ATTACH)
        {
            if(_currentTaskState == TASKSTATE_IDLE)
            {
                if(llLinksetDataRead(_p1))
                {
                    logInfo("Unable to rez with name \"" + _p1 + "\" as a placeholder with that name already exists.");
                    _currentTaskFailureMessage = "Placeholder with name \"" + _p1 + "\" already exists.";
                    _currentTaskState = TASKSTATE_FAILURE;
                }
                else
                {
                    if(currentActionType == ACTION_REZ)
                    {
                        vector myPos = llGetPos();
                        vector forwardOffset = <(float)_p2, 0.0, 0.0>; // Place the rezzed object x meters away based on the parameters of REZ
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
                llOwnerSay(_p1 + " [secondlife:///app/chat/" + (string)TEST_CHANNEL + "/" + ASK_YES + " " + ASK_YES + "] or [secondlife:///app/chat/" + (string)TEST_CHANNEL + "/" + ASK_NO + " " + ASK_NO + "]");
#elif ASK_TYPE == ASK_TYPE_DIALOG
                llDialog(llGetOwner(), _p1, [ASK_YES, ASK_NO], TEST_CHANNEL);
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
                if((key)_p1 == NULL_KEY)
                {
                    _currentTaskState = TASKSTATE_FAILURE;
                    _currentTaskFailureMessage = "Target key was NULL_KEY.";
                }
                else
                {
                    logVerbose("Sending: \"" + _p3 + "\" on channel: \"" + _p2 + "\"");

                    llRegionSayTo((key)_p1, (integer)_p2, _p3);
                    _sendTime = llGetTime();
                    _currentTaskState = TASKSTATE_SUCCESS;
                }
            }
        }
        else if(currentActionType == ACTION_RELAY)
        {
            if(_currentTaskState == TASKSTATE_IDLE)
            {
                if((key)_p1 == NULL_KEY)
                {
                    _currentTaskState = TASKSTATE_FAILURE;
                    _currentTaskFailureMessage = "Target key was NULL_KEY.";
                }
                else if((integer)_p4 != RELAY_TYPE_REGIONSAYTO && (integer)_p4 != RELAY_TYPE_SAY && (integer)_p4 != RELAY_TYPE_WHISPER && (integer)_p4 != RELAY_TYPE_SHOUT)
                {
                    _currentTaskState = TASKSTATE_FAILURE;
                    _currentTaskFailureMessage = "Invalid value type \"" + _p4 + "\" specified.";
                    return;
                }
                else
                {
                    logVerbose("Sending message of type: " + _p4 + " to be send on channel: " + _p2 + " message: " + _p3);
                    llRegionSayTo((key)_p1, TEST_CHANNEL, RELAY_COMMAND_RELAY + " " + _p4 + " " + _p2 + " " + _p3);
                    _relayTime = llGetTime();
                    _currentTaskState = TASKSTATE_SUCCESS;
                }
            }
        }
        else if(currentActionType == ACTION_EXPECT)
        {
            if(_currentTaskState == TASKSTATE_IDLE || _currentTaskState == TASKSTATE_WAITING)
            {
                float timeToCheck = 0;

                if((integer)_p4 == EXPECT_TYPE_SEND)
                    timeToCheck = _sendTime;
                else if((integer)_p4 == EXPECT_TYPE_RELAY)
                    timeToCheck = _relayTime;

                if((timeToCheck + (integer)_p3) > llGetTime())
                {
                    _currentTaskFailureMessage = "Unable to find \"" + _p2 + "\" among messages received.";
                    _currentTaskState = TASKSTATE_FAILURE;
                }

                integer i;
                integer len = llGetListLength(_receivedMessage);
                logVerbose("Received messages at this point: " + llDumpList2String(_receivedMessage, ", "));
                for(i = 0; i < len; i += 3)
                {
                    if((float)_receivedMessage[i + 2] > timeToCheck)
                    {
                        if((integer)_receivedMessage[i + 1] == (integer)_p1)
                        {
                            string message = (string)_receivedMessage[i];
                            string compare = _p2;
                            if(llSubStringIndex(compare, "*") != -1)
                            {
                                message = llGetSubString(message, 0, llSubStringIndex(compare, "*") - 1);
                                compare = llGetSubString(compare, 0, llStringLength(compare) - 2);
                            }
                            logVerbose("Current string comparison: " + message + " to compare it to: " + compare);
                            if(message == compare)
                            {
                                _currentTaskState = TASKSTATE_SUCCESS;
                                i = len;
                            }
                        }
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