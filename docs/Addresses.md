# Addresses 
Oranization of address space for the CPU.

## General 
* I/O peripherals are at the top of the available $2^{16}$ memory space. 
* Below the I/O addresses is the display data.
* the stack will start below the display data
* The lowest addresses will be code
* After the code will be storage for permanent data structures 
    * Glyph table 
    * Some data structure for locations of notes within the song


| Name | Lower Bound | Upper Bound |
| --------------- | --------------- | --------------- |
| Code | 0x0000 | depends on program |
| Data | after code | depends on program |
| Heap | after data | depends on execution |
| Stack | depends on execution | depends on screen layout |
| Screen Buffer | depends on screen layout | 0xFFEF |
| IO    | 0xFFF0     | 0xFFFF         |


## Peripherals
| Peripheral   | Address    |
|--------------- | --------------- |
| Switches      | 0xFFFF   |
| Buttons       | 0xFFFE   |
| Leds          | 0xFFFD   |
| HEX high      | 0xFFFC   |
| HEX low       | 0xFFFB   |
| VGA hCount    | 0xFFFA   | 
| VGA vCount    | 0xFFF9   | 
| music ctrl    | 0xFFF8   |
| drum pads     | 0xFFF7   |


