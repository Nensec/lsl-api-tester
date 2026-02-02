#define COMMON_ADD_TESTER ADD_TESTER
#define COMMON_WAIT_FOR_CONFIRM WAIT_FOR_CONFIRM
#define COMMON_REMOVE_TESTER REMOVE_TESTER
#define COMMON_REZ_DUMMY REZ_DUMMY
#define COMMON_ATTACH_DUMMY ATTACH_DUMMY

#define COLLECTIVE_PLACEHOLDERS \
    llLinksetDataWrite("IB", (string)(-1 - (integer)("0x" + llGetSubString((string)llGetOwner(), -7, -1)) + 5515));

#undef SETUPPLACEHOLDERS
#define SETUPPLACEHOLDERS DEFAULT_PLACEHOLDERS COLLECTIVE_PLACEHOLDERS

#undef TEST_DATA
#define TEST_DATA \
    ((ADD_AND_REMOVE, ([]), ((COMMON_ADD_TESTER))((COMMON_WAIT_FOR_CONFIRM))((COMMON_REMOVE_TESTER))(("Ask if device removed", ACTION_ASK, "Did the device get removed?")) )) \
    ((IDENTIFY, (["ADD_AND_REMOVE"]), (("Send identify", ACTION_SEND, "$AV", "$IB", "identify"))(("Identification", ACTION_EXPECT, "$IB", "identification*", 500, EXPECT_TYPE_SEND))(("Owners", ACTION_EXPECT, "$IB", "owners*", 500, EXPECT_TYPE_SEND))(("Software", ACTION_EXPECT, "$IB", "software*", 500, EXPECT_TYPE_SEND)))) \
    ((FOLLOW, (["ADD_AND_REMOVE"]), ((COMMON_REZ_DUMMY))((COMMON_ADD_TESTER))((COMMON_WAIT_FOR_CONFIRM))(("Send follow command", ACTION_SEND, "$AV", "$IB", "follow $DUMMY"))((COMMON_REMOVE_TESTER)) )) \
    ((ADDCOMMAND, (["ADD_AND_REMOVE"]), ((COMMON_ADD_TESTER))((COMMON_WAIT_FOR_CONFIRM))(("Send add command", ACTION_SEND, "$AV", "$IB", "add-command Test"))(("Ask if command added", ACTION_ASK, "Did the command get added?"))(("Remove commands command", ACTION_SEND, "$AV", "$IB", "remove-commands", _, _))(("Ask if commands removed", ACTION_ASK, "Did the command get removed?"))((COMMON_REMOVE_TESTER)) )) \
    ((ATTACH_REMOVE, ([]), ((COMMON_ATTACH_DUMMY))(("Relay add", ACTION_RELAY, "$ATTACH", "$IB", "add Relay", 0))(("Kill relay", ACTION_SEND, "$ATTACH", TEST_CHANNEL, "die"))(("Ask if device removed", ACTION_ASK, "Did the relay device get removed automatically?")) )) \

#define COLLECTIVE_COMMON_ACTIONS \
    ((COMMON_ADD_TESTER, "Add tester", ACTION_SEND, "$AV", "$IB", "add Tester")) /* Adds a device */ \
    ((COMMON_WAIT_FOR_CONFIRM, "Confirm add", ACTION_EXPECT, "$IB", "add-confirm", 500, EXPECT_TYPE_SEND)) /* Ensures the device is added by waiting for add-confirm */ \
    ((COMMON_REMOVE_TESTER, "Remove tester", ACTION_SEND, "$AV", "$IB", "remove Tester")) /* Removes the device */

#undef COMMON_ACTIONS // Remove definition so it can be re-defined
#define COMMON_ACTIONS DEFAULT_COMMON_ACTIONS COLLECTIVE_COMMON_ACTIONS // Re-define the common actions with the collective ones concatenated
