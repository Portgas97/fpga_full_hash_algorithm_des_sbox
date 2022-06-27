# Prototype for the project of Hardware and Embedded Security 2021/2022, Unipi
# Candidates: Francesco Venturini & Pierfrancesco Bigliazzi
# Professors: Sergio Saponara & Luca Crocetti
import binascii
from curses.ascii import LF
from math import floor
import string

# ############################################################################ #
# # # # # # # # # # # # # # # # #   CONSTANTS  # # # # # # # # # # # # # # # # # 
# ############################################################################ #

H_init = [b'0011',b'0000',b'1111',b'1101',b'0001',b'0111',b'1011',b'0100']
H_global = []

# S-Box
des_sbox = [
    ## columns
    #  0000     0001     0010     0011     0100     0101     0110     0111     1000     1001     1010     1011     1100     1101     1110     1111
    # row: 00
    [b'0010', b'1100', b'0100', b'0001', b'0111', b'1010', b'1011', b'0110', b'1000', b'0101', b'0011', b'1111', b'1101', b'0000', b'1110', b'1001'],
    # row: 01
    [b'1110', b'1011', b'0010', b'1100', b'0100', b'0111', b'1101', b'0001', b'0101', b'0000', b'1111', b'1100', b'0011', b'1001', b'1000', b'0110'],
    # rox:10
    [b'0100', b'0010', b'0001', b'1011', b'1100', b'1101', b'0111', b'1000', b'1111', b'1001', b'1100', b'0101', b'0110', b'0011', b'0000', b'1110'],
    # 11
    [b'1011', b'1000', b'1100', b'0111', b'0001', b'1110', b'0010', b'1101', b'0110', b'1111', b'0000', b'1001', b'1100', b'0100', b'0101', b'0011']
    ]


# ############################################################################ #
# # # # # # # # # # # # # # #   UTILITY  FUNCTIONS   # # # # # # # # # # # # # # 
# ############################################################################ #
# utility function to convert an ASCII character in its binary string representation

def ascii_to_binary(ascii_char):
    ascii_char = ascii_char.encode('ascii')
    binascii = int.from_bytes(ascii_char,'big')
    # print("format: ", f"{binascii:08b}")
    # print("binascii: ", binascii)
    # binary_output = bin(binascii)
    # print("binary_output: ", binary_output)
    return f"{binascii:08b}"

def int_to_binary_64(int_length):
    #convert the length of the message in 64 bits
    binlength = f"{int_length:064b}"
    # print("Length in 64 bits: " + str(binlength))
    return binlength


def rotl(input, d): 
    # slice string in two parts for left and right
    # print(input) 
    Lfirst = input[0:d] 
    Lsecond = input[d:]   
    # print ("Left Rotation : ", (Lsecond + Lfirst))
    # now concatenate two parts together 
    return Lsecond + Lfirst


def compression_function(char_8bit):
    # this is to have [0] as the LSB
    # print("Before inversion: ", char_8bit)
    char_8bit = char_8bit[::-1]
    # print("After inversion: ", char_8bit)
    char_6bit = str(int(char_8bit[3]) ^ int(char_8bit[2])) \
                + char_8bit[1] \
                + char_8bit[0] \
                + char_8bit[7] \
                + char_8bit[6] \
                + str(int(char_8bit[5]) ^ int(char_8bit[4]))
    # print("Compress function output: ", char_6bit) #  001010 with input 'A'
    return char_6bit

def final_compression_function(char_64bit, index):
    #this is to have [0] as the LSB
    #print("Before inversion: ", char_64bit)
    #print()
    char_64bit = char_64bit[::-1]
    #print("After inversion: ", char_64bit)#if the length is 1 byte then we have all 0s except the LSB which is 00000001 
    dim = 8
    char_6bit_index = str(int(char_64bit[(index*dim) + 7]) ^ int(char_64bit[(index*dim) + 1])) \
                      + char_64bit[(index*dim) + 3] \
                      + char_64bit[(index*dim) + 2] \
                      + str(int(char_64bit[(index*dim) + 5]) ^ int(char_64bit[(index*dim) + 0])) \
                      + char_64bit[(index*dim) + 4] \
                      + char_64bit[(index*dim) + 6]
    
    #if the length is 1 byte then we have
    #C6[0] = 000100
    #C6[1] = 000000
    #C6[2] = 000000
    #C6[3] = 000000
    #C6[4] = 000000
    #C6[5] = 000000
    #C6[6] = 000000
    #C6[7] = 000000

    return char_6bit_index


def compute_sbox(msg_char):
    # print("Computing sbox...")
    msg_char = ascii_to_binary(msg_char)
    msg_char = compression_function(msg_char)
    # consider that in 001010 the position 0 is the most of the left
    row = int((msg_char[0] + msg_char[5]), base=2) # order is important
    # print("row: ", row)
    column = int((msg_char[1] + msg_char[2] + msg_char[3] + msg_char[4]), base=2) #order is important
    # print("column: ", column)
    sbox_output = des_sbox[row][column]
    # print("sbox_output: ", sbox_output)
    return sbox_output

def xor(a, b):
    list = [_a ^ _b for _a, _b in zip(a, b)]
    string = ''.join(str(e) for e in list)
    bin_string = bytes(string, "ascii")
    return bin_string

def full_hash(H, msg_char):
    global H_global
    H_tmp = []
    print("H array: ")
    print(H)
    sbox_value = compute_sbox(msg_char)
    # print(sbox_value) 
    for r in range(4):
        # print("\n###########################################  ROUND " + str(r) + "  ###########################################")
        for i in range(8):
            # print("\n------------ Iterazione: " + str(i) + " ------------")
            # print(H[(i+1) % 8])
            # print(sbox_value)
            # print(xor(H[(i+1) % 8], sbox_value))
            tmp = (xor(H[(i+1) % 8], sbox_value))
            # print("tmp: ", tmp)
            H_tmp.insert(i, rotl(tmp, floor(i/2)))
            # print("iteration result H: ", H_tmp)
        # print()
        # print("Old H: ", H)
        H = H_tmp.copy()
        print("New H: ", H)
        H_global = H.copy()
        H_tmp = []

def final_hash(H, msg_length):
    global H_global
    H_tmp = []
    # print("Hash value: ")
    # print(H)
    msg_length = int_to_binary_64(msg_length)
    # print(msg_length)
    for i in range(8):
        # print("Iterazione: " + str(i))
        c6_index = final_compression_function(msg_length, i)
        # print("C6["  + str(i) + "] = " +str(c6_index))
        row = int((c6_index[0] + c6_index[5]), base =2)
        column = int((c6_index[1] + c6_index[2] + c6_index[3] + c6_index[4]), base = 2)
        sbox_value = des_sbox[row][column]
        # print()
        # print("Final hash des box output: ")
        # print(sbox_value)
        tmp = (xor(H[(i+1) % 8], sbox_value))
        # print("tmp(xor result): ", tmp)
        H_tmp.insert(i, rotl(tmp, floor(i/2)))
        # print("iteration result H: ", H_tmp)
        # print()
    # print("Old H: ", H)
    H = H_tmp.copy()
    print("New H: ", H)
    H_global = H_tmp.copy()
    H_tmp = []






# ############################################################################ #
# # # # # # # # # # # # # # # # # #   MAIN   # # # # # # # # # # # # # # # # # # 
# ############################################################################ #

# list of ASCII printable characters
# alphabet = list(string.printable)
# print("alphabet:\n", alphabet)

# # list of ASCII printable characters in binary representation
# binary_alphabet = [ ascii_to_binary(a) for a in alphabet]
# print("binary_alphabet :\n", binary_alphabet)

# message input
print("Insert the message you want to hash:\n")
msg = input()
msg_list = list(msg)
len = len(msg_list)
print("Message entered. Start hashing...\n")
print("\nLength of the message: ", len)


H_global = H_init
H_output = []
# hash computation 
for i in range(len):
    print("Character: ", msg_list[i])
    full_hash(H_global, msg_list[i])
    for j in range(8):
        H_output.insert(j, hex(int(H_global[j],2))[2:])
    print()
    print(''.join(H_output))
    H_output = []

final_hash(H_global,len)
print("Result: ")
print(H_global)
for j in range(8):
    H_output.insert(j, hex(int(H_global[j],2))[2:])
H_output.reverse()
print(''.join(H_output))
H_output = []

