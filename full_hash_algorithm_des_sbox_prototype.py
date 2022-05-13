# Prototype for the project of Hardware and Embedded Security 2021/2022, Unipi
# Candidates: Francesco Venturini & Pierfrancesco Bigliazzi
# Professors: Sergio Saponara & Luca Crocetti
from math import floor
import string

# ############################################################################ #
# # # # # # # # # # # # # # # # #   CONSTANTS   # # # # # # # # # # # # # # # # # 
# ############################################################################ #

H_init = [b'0100',b'1011',b'0111',b'0001',b'1101',b'1111',b'0000',b'0011']
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
    #print("format: ", f"{binascii:08b}")
    # print("binascii: ", binascii)
    # binary_output = bin(binascii)
    # print("binary_output: ", binary_output)
    return f"{binascii:08b}"


def rotl(input,d): 
    # slice string in two parts for left and right
    print(type(input))
    print(input) 
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
    print("Compress function output: ", char_6bit) #  001010 with input 'A'
    return char_6bit

# TO CHECK
def compute_sbox(msg_char):
    print("Computing sbox...")
    msg_char = ascii_to_binary(msg_char)
    msg_char = compression_function(msg_char)
    # consider that in 001010 the position 0 is the most of the left
    row = int((msg_char[0] + msg_char[5]), base=2) # order is important
    # print("row: ", row)
    column = int((msg_char[1] + msg_char[2] + msg_char[3] + msg_char[4]), base=2) #order is important
    # print("column: ", column)
    sbox_output = des_sbox[row][column]
    print("sbox_output: ", sbox_output)
    return sbox_output

def xor(a, b):
    return bytes([_a ^ _b for _a, _b in zip(a, b)])

# TO CHECK
def full_hash(H, msg_char):
    H_tmp = []
    print("H array: ")
    print(H)
    sbox_value = compute_sbox(msg_char)
    for r in range(4):
        print("\n###########################################  ROUND " + str(r) + "  ###########################################")
        for i in range(8):
            print("\n ############# Iterazione: ", i)

            # print(H[(i+1) % 8])
            # print(sbox_value)
            # print(xor(H[(i+1) % 8], sbox_value))
            tmp = (xor(H[(i+1) % 8], sbox_value))
            # print("H_tmp["+str(i)+"]: ", H_tmp[i])

            H_tmp.append(rotl(tmp, floor(i/2)))
            print("iteration result: ", H_tmp[i])
    H_global = H_tmp


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
# hash computation 
for i in range(len):
    print("Character: ", msg_list[i])
    full_hash(H_global, msg_list[i])

# TODO ...


