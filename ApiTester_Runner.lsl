#define LOADING_RUNNER
#include <Tester/ApiTester.lsl>
#undef LOADING_RUNNER

default
{
    state_entry()
    {
    }
}

state load_next_test
{
    state_entry()
    {        
    }
}

state run_test
{
    timer()
    {
        timerFunction();
    }
}