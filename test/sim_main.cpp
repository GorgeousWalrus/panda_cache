#include <verilated.h>
#include "Vcache_tb.h"
#include "testbench.h"

typedef unsigned __int128 uint128_t;

TESTBENCH<Vcache_tb> *tb;

int read_mem(int addr){
    tb->m_core->addr_i = addr;
    tb->m_core->read_i = 1;
    tb->tick();
    while(tb->m_core->valid_o != 1){
        tb->tick();
    }
    int data = tb->m_core->data_o;
    tb->m_core->read_i = 0;
    return data;
}

void write_mem(int addr, int data){
    tb->m_core->addr_i = addr;
    tb->m_core->data_i = data;
    tb->m_core->write_i = 1;
    tb->tick();
    while(tb->m_core->valid_o != 1){
        tb->tick();
    }
    tb->m_core->write_i = 0;
    return;
}

int test_cache(){
    for(int i = 0; i <40; i++){
        if(read_mem(i*4) != i)
            return i+1;
    }
    write_mem(0x8, 0xff);
    if(read_mem(0x8) != 0xff) return -1;

    for(int i = 0; i < 1000; i++)
        read_mem(i*4);
    
    if(read_mem(0x8) != 0xff) return -2;
    write_mem(0x8, 2);
        
    for(int i = 0; i <40; i++){
        if(read_mem(i*4) != i)
            return i+1;
    }
    return 0;
}

int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    tb = new TESTBENCH<Vcache_tb>();
    tb->opentrace("logs/trace.vcd");
    int result = 0;

    // Initialize inputs

    // Reset
    tb->reset();

    // Run tests
    result = test_cache();
    
    // Cleanup
    tb->tick();
    tb->m_core->final();

    // Evaluate test
    if(result == 0)
        std::cout << "PASSED" << std::endl;
    else
        std::cout << "FAILED " << result << std::endl;
    
    //  Coverage analysis (since test passed)
    VerilatedCov::write("logs/coverage.dat");

    // Destroy model
    delete tb->m_core; tb->m_core = NULL;

    exit(0);
}
