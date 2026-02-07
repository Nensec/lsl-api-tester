// ####################################################################################
// -- Changelog, tester information, readme, and instructions to create a new tester --
// ####################################################################################

// V's Tester v1.0, by Voisin (Nensec Resident)
// Latest version can always be found on github: https://github.com/Nensec/lsl-api-tester
// Feel free to modify and redistribute this script however you please, I simply ask that you keep my name as the original author by keeping the changelog intact and simply add your own changelog.

// -- Changelog

// v1.0: Initial version - Voisin (Nensec Resident)

// -- What is it

// The purpose of this script is to help automate the testing of your API. It does so by using pre-defined blocks of code to define what a test is and what it should do.
// By using pre-defined blocks you eliminate, or at least heavily reduce, contamination of copy pasting or other code. You are also ensured that every time you use that block it will do the same thing.
// 

// This tester script is in part self-generating, all you have to do is define data and the code will be generated using the Boost preprocessor.
// The resulting compiled code is, as a result, less than stellar to read. If you do not have a preprocessor enabled and was given this script, that would be why.
// As such in order to compile this script you need to have the Boost files ready on your local hard drive and have your preprocessor configured to find these files
// In Firestorm, where this script is build for, you just have to ensure that your include path has access to the boost folder in its root such that the above #include's are correct.
// You can of course alter the includes above to match your folder structure.

// Boost can be downloaded from here: https://www.boost.org/releases/latest/
// I suggest grabbing a zip and just unpack it where you need it.

// -- How to use

// If you received this script stand alone you need it's companion script: ApiTester_Relay.lsl.
// **COMING SOON in v1.1** Additionally, if your test suite is so large that this script runs into memory problems and stack heaps you can instead use the runner mode option and require the ApiTester_Runner.lsl script
// All scripts, and thus its latest versions, can be found at on my github: https://github.com/Nensec/lsl-api-tester
// As this script is meant for developers, I welcome forking and subsequent pull requests with modifications!

// The tester has 3 objects that it uses.
//  - The tester object. ApiTester.lsl and ApiTester_Runner.lsl live in here. (The latter is optional and dependant on configuration here!)
//  - A rezzable object. ApiTester_Relay.lsl lives in here. This object is meant to be rezzed, as such it requires to be Copy/Modify.
//  - An attachable object. ApiTester_Relay.lsl lives in here as well. This object is meant to be temporary attached, as such it also requires to be Copy/Modify.
// The rezzable object and attachable object need to be in the inventory of the tester object.

// To configure the tester simply modify the output of the macros below according to the comments, some things do not need to be changed whilst other things will according to your API needs.

// ####################################################################################
// -- Adjust the macro outputs to your testing needs by following instructions below --
// ####################################################################################

// Turn off which logging you do not want by commenting out the log level. Turning all off will result in only the test result to be output.
// Turning off logging will help a lot in script memory, it is recommended to only turn on logging when you are experiencing problems and when you do turn off irrelevant tests by commenting them out.
// Logging adds a lot of memory!
#define INFO
#define VERBOSE
//#define LISTENER // This will dump all content you receive from listeners you have specified in EXPECT's in a test, it can be very spammy depending on how much chatter you have on your channel(s)!

// Tester configuration
#define TESTER_MODE TESTER_MODE_LOCAL // Run the script locally (TESTER_MODE_LOCAL) in just this script or use a runner script (TESTER_MODE_RUNNER) that contains all the logic, this will save on memory but uses link messages to control the test flow.
#define LOAD_LOCAL_TESTS TRUE // Loads tests locally defined using the Boost preprocessor, if set to FALSE will not require Boost at all to be installed
#define LOAD_NOTECARDS_TESTS TRUE // Attempts to load JSON notecards with test data
#define TEST_CHANNEL -8378464 // This is the channel that the tests and relay communicate on, all listeners are filtered by owner avatar id.

#define ASK_TYPE ASK_TYPE_DIALOG // Should the ASK action request a reply in a clickable chat message (ASK_TYPE_CHAT), or should it show a dialog with buttons (ASK_TYPE_DIALOG)?

#define DUMMY_OBJECT "Dummy" // The name of the Relay object to rez when REZ is used. This object has to exist in the inventory where this tester script lives and must contain the ApiTester_Relay.lsl script.
#define DUMMY_OBJECT_ROTATION <90.0, 270.0, 0.0> // Adjust the rotation of the dummy object so it faces a specific direction
#define DUMMY_OBJECT_HEIGHT 0.64528 // The height of the dummy object so REZ places it on the floor

#define DUMMY_ATTACH "Attach" // The name of the Relay object to rez and attach when ATTACH is used. This object has to exist in the inventory where this tester script lives and must contain the ApiTester_Relay.lsl script.
#define DUMMY_ATTACH_POINT 35 // See https://wiki.secondlife.com/wiki/LlAttachToAvatar for attachment points

// Define tests and their actions, these tell a 'story'. e.g. "After we SEND add Tester we EXPECT to return add-confirm." or "After we SEND remove Tester we ASK Did the device manager report the device \"Tester\" was removed?"
//
// The first parameter of the tuple is the name of the test, no spaces allowed.
// The second parameter of the tiple is a list of dependencies, this allows you to skip tests if you know they will fail because it's function is reliant on another test being succesful
// The third parameter of the tuple is a list of tuples that define actions to be executed for this test.
//
// Note: You need to double up the brackets.
//
// Examples:
//  (("ADD", ([]), (("Add tester", ACTION_SEND, "$AV", "$IB", "add Tester"))(("Look for add-confirm", ACTION_EXPECT, "$IB", "add-confirm", 500, EXPECT_TYPE_BEGINNING)) ))
//  (("REMOVE", (["ADD"]), (("Remove tester", ACTION_SEND, "$AV", "$IB", "remove Tester"))(("Ask if device removed", ACTION_ASK, "Did the device manager report it?")) ))
//
// Placeholders are supported, data gets retrieved from LSD. Starting a string using a $ tells the test script to fetch that name from LSD. If not then the raw value is used.
// See the SETUPPLACEHOLDERS() macro for available placeholders
//
// The parameters are as follows:
//  Name, Action Type, First Parameter, Second Parameter, Third Parameter, Fourth Parameter
// The name gets output in the log.
// It is recommended to use the macros for the actions, to ensure there are no typos. Simply prepend ACTION_ to the type of action to use the macro version. e.g. ACTION_SEND or ACTION_EXPECT.
//
// Available actions:
//
// SEND:
// Send a message on a channel to kick off the test.
//  Parameters:
//      key target
//      integer channel
//      string message
//
// EXPECT:
// Assert a certain value is returned since beginning of test, SEND or RELAY. If a * is added any remaining string after the * is ignored. Useful for commands that return a value not known ahead of time, but do fit a pattern.
//  Parameters:
//      integer channel
//      string value
//      integer time (in milliseconds)
//      integer type
//  Types:
//      EXPECT_TYPE_BEGINNING: Beginning of test
//      EXPECT_TYPE_SEND: Since last SEND
//      EXPECT_TYPE_RELAY: Since last RELAY
//
// ASK:
// Ask a Yes/No question, if answered with No then the test is marked as failed.
//  No max.
//  Parameters:
//      string message
//
// REZ:
// Rezzes a Relay object. It's name gets added to LSD as a placeholder with the value being its UUID. The Relay object houses a simple relaying script that allows the RELAY function to send messages via the Relay object.
//  Names however need to be unique for each.
//  Parameters:
//      string name
//      float distance (max 10, SL limit)
//
// ATTACH:
// Rezzes a Relay object. It's name gets added to LSD as a placeholder with the value being its UUID. The Relay object houses a simple relaying script that allows the RELAY function to send messages via the Relay object.
//  Names however need to be unique for each.
//  Parameters:
//      string name
//
// RELAY:
// Instructs a given Relay object to relay a message.
//  Parameters:
//      key relay
//      integer channel
//      string value
//      integer channelType
//  Types:
//      RELAY_TYPE_REGIONSAYTO: RegionSayTo (target = llGetOwner)
//      RELAY_TYPE_SAY: llSay
//      RELAY_TYPE_WHISPER: llWhisper
//      RELAY_TYPE_SHOUT: llShout
//
#if LOAD_LOCAL_TESTS==TRUE
#define TEST_DATA 
#endif
// Define common functions that are required in many tests, this will save on script memory because these will only be generated once.
// They follow the same pattern as actions in the TEST_DATA macro, where the name is the key of the function. I recommend making macros for the keys so you can easily use them without typos.
// These functions usually correspond to stand alone tests, where those tests then become dependencies of future tests.
// For example: Your API requires a script to announce itself first before it will accept a command from the script, rather than writing the full ACTION_SEND to authenticate as part of the test data simply define it once here and use it in place of an action.
// A set of default common actions is available in DEFAULT_COMMON_ACTIONS. You can completely omit these if you do not use them.
//
// Example:
// #define COMMON_ACTIONS \
//         ((COMMON_REZ_DUMMY, "Rez dummy", ACTION_REZ, "DUMMY", 2.5)) /* Rezzes a dummy with the name DUMMY as placeholder at 2.5m distance */ \
//         ((COMMON_ATTACH_DUMMY, "Attach dummy", ACTION_ATTACH, "ATTACH")) /* Attaches a dummy with the name ATTACH as placeholder */
//
#if LOAD_LOCAL_TESTS==TRUE
#define COMMON_ACTIONS DEFAULT_COMMON_ACTIONS
#endif
// Add a new llLinksetDataWrite for every placeholder you want to add, you can always call a function as well if something is especially complex to calculate.
// Where applicable you can insert these placeholder values by prefixing its name with a $ symbol.
// A set of default placeholders  is available in DEFAULT_PLACEHOLDERS. You can completely omit these if you do not use them.
//
// Example:
// #define SETUPPLACEHOLDERS \
//         llLinksetDataWrite("AV", llGetOwner()); \
//
// Note: the LSD is wiped on every rez and re-filled during initialization of the tester.
#define SETUPPLACEHOLDERS DEFAULT_PLACEHOLDERS

// Tip: Rather than define all of your tests in this script and keep copies of this entire script around, simply make them in a separate file and #include <yourtests.lsl>.
// Just #define TEST_DATA, #define COMMON_ACTIONS and #define SETUPPLACEHOLDERS in there, make sure to #undef the macros in here or comment them out here!
// That way you only need to change one line of code to change your entire test suite!
// Note: When overriding do not forget to include the DEFAULT_COMMON_ACTIONS and DEFAULT_PLACEHOLDERS if you use them!

// ####################################################################################
// -- Below here should not be edited by the user unless you know what you are doing --
// ####################################################################################

// Tester constants
#define TESTER_MODE_LOCAL 0
#define TESTER_MODE_RUNNER 1

#if TESTER_MODE==TESTER_MODE_RUNNER
    #error "Runner mode is not yet implemented, coming soon in v1.1!"
#endif

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

#define COMMON_REZ_DUMMY REZ_DUMMY
#define COMMON_ATTACH_DUMMY ATTACH_DUMMY

#define DEFAULT_PLACEHOLDERS \
        llLinksetDataWrite("AV", llGetOwner()); \
        llLinksetDataWrite("TESTCHANNEL", (string)TEST_CHANNEL);

// -- Start of preprocessor macros
#if LOAD_LOCAL_TESTS==TRUE
#include <boost/preprocessor/seq/for_each_i.hpp>
#include <boost/preprocessor/seq/for_each.hpp>
#include <boost/preprocessor/tuple/elem.hpp>
#include <boost/preprocessor/punctuation/comma_if.hpp>
#include <boost/preprocessor/control/if.hpp>
#include <boost/preprocessor/control/iif.hpp>
#include <boost/preprocessor/comparison/equal.hpp>
#include <boost/preprocessor/tuple/size.hpp>
#include <boost/preprocessor/tuple/pop_front.hpp>
#include <boost/preprocessor/cat.hpp>

#define DEFAULT_COMMON_ACTIONS \
    ((COMMON_REZ_DUMMY, "Rez dummy", ACTION_REZ, "DUMMY", 2.5)) /* Rezzes a dummy with the name DUMMY as placeholder at 2.5m distance */ \
    ((COMMON_ATTACH_DUMMY, "Attach dummy", ACTION_ATTACH, "ATTACH")) /* Attaches a dummy with the name ATTACH as placeholder */

// Helpers
#define _ ""
#define GLUE_STR(...) #__VA_ARGS__
#define DEFER_STR(...) GLUE_STR(__VA_ARGS__)

#define GET_TEST_NAME(r, data, i, elem) BOOST_PP_COMMA_IF(i) DEFER_STR(BOOST_PP_TUPLE_ELEM(0, elem))

// Create JSON
#define BUILD_JSON(r, data, i, elem) \
    BOOST_PP_COMMA_IF(i) \
    BOOST_PP_IIF(BOOST_PP_EQUAL(BOOST_PP_TUPLE_SIZE(elem), 1), PROCESS_ELEM_REF, PROCESS_ELEM)(elem)

#define PROCESS_ELEM_REF(elem) DEFER_STR(BOOST_PP_TUPLE_ELEM(0,elem))
#define PROCESS_ELEM(elem) \
    BOOST_PP_IF( \
        BOOST_PP_EQUAL(BOOST_PP_TUPLE_SIZE(elem), 3), \
        PROCESS_ELEM_ONE_PARAM, \
        BOOST_PP_IF( \
            BOOST_PP_EQUAL(BOOST_PP_TUPLE_SIZE(elem), 4), \
            PROCESS_ELEM_TWO_PARAM, \
            BOOST_PP_IF( \
                BOOST_PP_EQUAL(BOOST_PP_TUPLE_SIZE(elem), 5), \
                PROCESS_ELEM_THREE_PARAM, \
                PROCESS_ELEM_FOUR_PARAM \
            ) \
        ) \
    )(elem)

#define PROCESS_ELEM_ONE_PARAM(elem) {"n":BOOST_PP_TUPLE_ELEM(0,elem),"a":BOOST_PP_TUPLE_ELEM(1,elem),"p":[BOOST_PP_TUPLE_ELEM(2,elem)]}
#define PROCESS_ELEM_TWO_PARAM(elem) {"n":BOOST_PP_TUPLE_ELEM(0,elem),"a":BOOST_PP_TUPLE_ELEM(1,elem),"p":[BOOST_PP_TUPLE_ELEM(2,elem),BOOST_PP_TUPLE_ELEM(3,elem)]}
#define PROCESS_ELEM_THREE_PARAM(elem) {"n":BOOST_PP_TUPLE_ELEM(0,elem),"a":BOOST_PP_TUPLE_ELEM(1,elem),"p":[BOOST_PP_TUPLE_ELEM(2,elem),BOOST_PP_TUPLE_ELEM(3,elem),BOOST_PP_TUPLE_ELEM(4,elem)]}
#define PROCESS_ELEM_FOUR_PARAM(elem) {"n":BOOST_PP_TUPLE_ELEM(0,elem),"a":BOOST_PP_TUPLE_ELEM(1,elem),"p":[BOOST_PP_TUPLE_ELEM(2,elem),BOOST_PP_TUPLE_ELEM(3,elem),BOOST_PP_TUPLE_ELEM(4,elem),BOOST_PP_TUPLE_ELEM(5,elem)]}

#define BUILD_DEPENDENCIES(r, data, i, elem) BOOST_PP_COMMA_IF(i) elem

// Generate LSL
#define TEST_WRITER(r, data, elem) \
    llLinksetDataWrite(DEFER_STR(BOOST_PP_CAT(T_, BOOST_PP_TUPLE_ELEM(0, elem))), DEFER_STR({"d":[BOOST_PP_SEQ_FOR_EACH_I(BUILD_DEPENDENCIES, _, BOOST_PP_TUPLE_ELEM(1, elem))],"a":[BOOST_PP_SEQ_FOR_EACH_I(BUILD_JSON, _, BOOST_PP_TUPLE_ELEM(2, elem))]}));

#define COMMON_ACTION_WRITER(r, data, elem) \
    llLinksetDataWrite(DEFER_STR(BOOST_PP_CAT(C_, BOOST_PP_TUPLE_ELEM(0, elem))), DEFER_STR(PROCESS_ELEM(BOOST_PP_TUPLE_POP_FRONT(elem))));

// -- End of preprocessor macros

list _tests = [BOOST_PP_SEQ_FOR_EACH_I(GET_TEST_NAME, _, TEST_DATA)]; // All tests
#else
list _tests = [];
#endif

integer _activeTest = -1; // Index of current test
integer _activeTestState = TESTSTATE_IDLE; // Current state of the test

integer _currentTask = 0; // The current task
string _currentTaskData; // JSON data of current task
integer _currentTaskState = TESTSTATE_IDLE; // Current state of the current task
string _currentTaskFailureMessage;

list _receivedMessage = []; // Strided list of 3: [message, channel, timestamp]
list _rezzedDummies = []; // All of the dummies rezzed during the current test

string  _p1;
string  _p2;
string  _p3;
string  _p4;

float _rezTime; // When was the last REZ
float _sendTime; // When was the last SEND
float _relayTime; // when was the last RELAY
float _askTime; // when was the last ASK

float _touch;

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

        result += llLinksetDataRead(placeholder);
        i = llSubStringIndex(param, "$");
    }

    return result + param;
}

#if LOAD_NOTECARDS_TESTS==TRUE
list _notecardQueries = [];
#endif

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

        logInfo("Next task is: " + llJsonGetValue(_currentTaskData, ["a"]));
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

saveRezzedDummy(key id)
{
    string dummyName = llJsonGetValue(_currentTaskData, [ACTION_1STPARAM]);
    logVerbose("Saving placeholder \"" + dummyName + "\" with value: \"" + (string)id + "\".");
    llLinksetDataWrite(dummyName, id); // Save the rezzed object in LSD so it can be used as a placeholder
    llRegionSayTo(id, TEST_CHANNEL, RELAY_COMMAND_INIT + " " + dummyName);
    _rezzedDummies += [dummyName + ":" + (string)id];
    _currentTaskState = TASKSTATE_SUCCESS;
}

default
{
    state_entry()
    {
        logInfo("Wiping LSD.");
        llLinksetDataReset();

        SETUPPLACEHOLDERS
#ifdef VERBOSE
        logVerbose("Placeholders saved in LSD:");
        list keys = llLinksetDataListKeys(0, 0);
        for(;keys;keys=llDeleteSubList(keys,0,0))
            llOwnerSay("    " + (string)keys[0] + ": " + llLinksetDataRead((string)keys[0]));
#endif
#ifdef INFO
        integer testCount = llGetListLength(_tests);
        logInfo("Loading " + (string)testCount + " tests..");
#endif
        logVerbose("Tests: " + llDumpList2String(_tests, ", "));
        BOOST_PP_SEQ_FOR_EACH(TEST_WRITER, _, TEST_DATA)
        BOOST_PP_SEQ_FOR_EACH(COMMON_ACTION_WRITER, _, COMMON_ACTIONS)
        logInfo("Local tests loaded.");
#if LOAD_NOTECARDS_TESTS==TRUE
        logInfo("Loading notecard tests..");
        integer count = llGetInventoryNumber(INVENTORY_NOTECARD);
        string name;
        string queryId;
        while(count--)
        {
            name = llGetInventoryName(INVENTORY_NOTECARD, count);
            queryId = (string)llGetNotecardLine(name, 0);
            _notecardQueries += [name + ":" + queryId + ":0"];
            logVerbose("Loading notecard: \"" + name + "\".");
        }
#endif

        integer memused = llGetUsedMemory();
        integer memmax = llGetMemoryLimit();
        integer memfree = llGetFreeMemory();
        integer memperc = (integer)(100.0 * (float)memused/memmax);
        integer lsdAvailable = llLinksetDataAvailable();

        log("Memory Used: " + (string)memused + "\nMemory Free: " + (string)memfree + "\nMemory Limit: " + (string)memmax + "\nPercentage of Memory Usage: " + (string)memperc + "%.");
        log("LSD available: " + (string)lsdAvailable + " / 131072 (" + (string)((integer)(100 * (float)lsdAvailable/131072)) + "%).");

        log("Ready to start. Touch this object to start the test suite.");
    }
#if LOAD_NOTECARDS_TESTS==TRUE
    dataserver(key queryid, string data)
    {
        integer i;
        integer len = llGetListLength(_notecardQueries);
        for(i = 0; i < len; i++)
        {
            logVerbose((string)_notecardQueries[i]);
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
                    llListReplaceList(_notecardQueries, [name + ":" + _queryId + ":" + (string)lineIndex], i, i);
                }

                if (data == EOF)
                {
                    llLinksetDataWrite("NC_" + name, notecardTestData);
                    //llLinksetDataDelete("NC_" + name);
                    if(llJsonValueType(notecardTestData, []) == JSON_INVALID)
                        log("Notecard \"" + name + "\" does not contain valid JSON.");
                    #ifdef VERBOSE
                    else
                        logVerbose("Notecard \"" + name + "\" loaded.");
                    #endif
                }

                return;
            }
        }
    }
#endif
    touch_start(integer num_detected)
    {
        log("Starting test suite.");
        state load_next_test;
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
    }

    touch_start(integer num_detected)
    {
        _touch = llGetTime();
    }

    touch(integer num_detected)
    {
        if(_touch != 0 && (_touch + 3.0) < llGetTime())
            llResetScript();
    }

    touch_end(integer num_detected)
    {
        _touch = 0;
        list testData = llLinksetDataFindKeys("R_", 0, 0);
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

        list params = llJson2List(llJsonGetValue(_currentTaskData, ["p"]));
        _p1 = getParameter((string)params[0]);
        _p2 = getParameter((string)params[1]);
        _p3 = getParameter((string)params[2]);
        _p4 = getParameter((string)params[3]);

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
            
            if(_currentTaskState == TASKSTATE_FAILURE)
            {
                reportTaskState();
                state load_next_test;
            }
            else if(_currentTaskState == TASKSTATE_SUCCESS)
                loadNextTask();
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
            
            if(_currentTaskState == TASKSTATE_FAILURE)
            {
                reportTaskState();
                state load_next_test;
            }
            else if(_currentTaskState == TASKSTATE_SUCCESS)
                loadNextTask();
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
                    logVerbose("Sending: \"" + _p1 + "\" on channel: \"" + _p2 + "\"");

                    llRegionSayTo((key)_p1, (integer)_p2, _p3);
                    _sendTime = llGetTime();
                    _currentTaskState = TASKSTATE_SUCCESS;
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
            
            if(_currentTaskState == TASKSTATE_FAILURE)
            {
                reportTaskState();
                state load_next_test;
            }
            else if(_currentTaskState == TASKSTATE_SUCCESS)
                loadNextTask();
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


            if(_currentTaskState == TASKSTATE_FAILURE)
            {
                reportTaskState();
                state load_next_test;
            }
            else if(_currentTaskState == TASKSTATE_SUCCESS)
                loadNextTask();
        }
    }
}