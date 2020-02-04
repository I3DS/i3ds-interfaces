# I3DS ASN.1 interfaces

Extends the esrocos datatypes fo use with I3DS. To generate files for
use with the i3ds-framework-cpp and other in need of the ASN.1
encoders/decoders.

# Building
``` shell
./scripts/simple.sh
```

This will kick of a series of steps via cmake:
 1. Generate files from ASN.1 definitions.
 2. ASN.1 Compilation done, processing for library compilation.
 3. Compile the library and create the .so
 4. Compile done, creating install-bundle.

The result is a tar-archive with the .so and headers, ready to be
installed on target

## Big, fat warning

In order to ensure proper encapsulation so that we can include
libi3ds_asn1.so in systems that also hooks into TASTE, we are creating a
C++ namespace as well as prefixing #defines with the same namespace.

asn1.exe can prefix both types and fields, but it does not cover
everything. Most notably:
- #defines are (mostly) not touched
- core asn1cc-files are not touched

There are also examples where fields in enums are not updated, yet enums
defined inside structs are.

For this reason, we are dropping both and instead do a dynamic rewriate
*after* the code has been genearted where we:
- update include statements for asn1-files (requiered when moving to
  .so)
- add C++ namespace to all files
- prefix all #define symbols with same namespace
- rename files to cpp/hpp
- move files into proper include hierarchy

## Adding a new subsystem

This project is split into subsystems, currently 'esrocos' and
'i3ds'. The former is the governing system providing base-types etc, the
latter is a more specific project (i3ds) that uses these definitions
internally.

To add to an existing subsystem, simply place the new asn-file in the
appropriate directoy and update asn1.list for that subsystem.

To add a new subsystem, copy the directoy layout of esrocos and add a
new asn1.list on the same form. generate.sh expects this file to return
a string with all relevant asn1-files.

# Using libi3ds_asn.so

To use in an existing project with CMake, see i3ds-framework-cpp (some
hash)

To use directly in a smaller project without installing it into the
standard paths, unpack the archive and point to the relevant directories
for g++:

``` shell
tar xvf esrocos_asn1-2019-11-deadbeef1234.tar -C .
g++ -c test_cpp.cpp lib.cpp -Iinclude
g++ -o test_cpp test_cpp.o lib.o -Llib/ -li3ds_asn1
LD_LIBRARY_PATH=lib/ ./test_cpp
```

Example snippet:

``` C++
#include <iostream>
#include <i3ds_asn1/Sensor.hpp>

int main()
{
    /* can access header-content? */
    std::cout << "Testing access to header: sampleperiod: " << i3ds_asn1_ERR_SAMPLEPERIOD_2 << std::endl;
    i3ds_asn1::Asn1ObjectIdentifier aoi;
    std::cout << "sizeof(i3ds_asn1::Asn1ObjectIdentifier): " << sizeof(aoi) << std::endl;

    // /* can link and call into .so? */
    i3ds_asn1::SensorStatus status;
    int errCode = 0;

    //i3ds_asn1::SensorStatus_Initialize(&status);
    i3ds_asn1::asn1SccSint asi = 3;
    i3ds_asn1::asn1SccUint aui = i3ds_asn1::int2uint(asi);

    status.current_state = i3ds_asn1::failure;
    SensorStatus_IsConstraintValid(&status, &errCode);

    printf("Valid: %d (%d)\n", errCode, status.current_state);
    return 0;
}

# Testing access to header: sampleperiod: 9957
# sizeof(i3ds_asn1::Asn1ObjectIdentifier): 168
# Valid: 0 (3)

```
