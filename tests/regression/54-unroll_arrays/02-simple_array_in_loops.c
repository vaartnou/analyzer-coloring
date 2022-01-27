// PARAM: --set solver td3 --enable ana.int.interval --set exp.arrays-domain unroll --set exp.array-unrolling-factor 2
int global;

int main(void)
{
    example1();
    example2();
    return 0;
}

// Simple example
void example1(void)
{
    int a[42];
    int i = 0;
    int top;

    while (i < 42) {
        a[i] = 0;
        assert(a[i] == 0); // UNKNOWN
        assert(a[0] == 0); // UNKNOWN
        assert(a[17] == 0); // UNKNOWN
        i++;
    }

    assert(a[0] == 0); // UNKNOWN
    assert(a[7] == 0); // UNKNOWN
    assert(a[41] == 0); // UNKNOWN
}


// Check that arrays of types different from int are handeled correctly
void example2() {
    char a[10];
    int n;
    assert(a[3] == 800); // FAIL

    for(int i=0;i < 10; i++) {
        a[i] = 7;
    }

    a[3] = (char) n;
    assert(a[3] == 800); //FAIL
    assert(a[3] == 127); //UNKNOWN
    assert(a[3] == -128); //UNKNOWN
    assert(a[3] == -129); //FAIL
}
