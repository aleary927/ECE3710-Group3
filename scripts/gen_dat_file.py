#!/bin/python3
# 
# This script takes a programming file of size 2^16, and an aditional data file, and 
# appends the data file starting at address 2^16, going no more than 2^18. 

import argparse

OUT_LEN = 2**18
CODE_LEN = 2**16

def combineFiles(code_file, audio_file, output_file):
    print(code_file)

    out = open(output_file, "w") 
    code = open(code_file, "r") 
    audio = open(audio_file, "r")

    code_len = len(code.readlines())
    audio_len = len(audio.readlines())
    code.seek(0) 
    audio.seek(0)

    if code_len != CODE_LEN: 
        print("warning: code file short")

    extra_lines = OUT_LEN - code_len - audio_len

    if extra_lines < 0: 
        print("warning: audio file too big, data will be lost")
    
    out.write(code.read())
    out.write(audio.read())

    if extra_lines > 0:
        for _ in range(extra_lines): 
            out.write("0000\n")

    code.close() 
    audio.close()
    out.close()

def main ():
    parser = argparse.ArgumentParser(description="Generate programming file")
    parser.add_argument("code_file", help="Assembled code file from assembler")
    parser.add_argument("audio_file", help="Audio file containing samples")
    parser.add_argument("-o", help="File to store result in")

    args = parser.parse_args()
    # print(args)
    output_file = args.o

    if output_file == None: 
        output_file = "a.dat"

    combineFiles(args.code_file, args.audio_file, output_file)


if __name__  == "__main__": 
    main()
