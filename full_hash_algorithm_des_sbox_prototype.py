# Prototype for the project of Hardware and Embedded Security 2021/2022, Unipi
# Candidates: Francesco Venturini & Pierfrancesco Bigliazzi
# Professors: Sergio Saponara & Luca Crocetti
from math import floor
import string

# ############################################################################ #
# # # # # # # # # # # # # # # # #   COSTANTS   # # # # # # # # # # # # # # # # # 
# ############################################################################ #

H_init = [b'0100',b'1011',b'0111',b'0001',b'1101',b'1111',b'0000',b'0011']
H_global = [8]

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
    binary_output = bin(binascii)
    return binary_output

# implements left rotation
def rotl(num, bits):
    bit = num & (1 << (bits-1))
    num <<= 1
    if(bit):
        num |= 1
    num &= (2**bits-1)
    return num

# TO CHECK
def full_hash(H, msg_char):
    H_tmp = [8]
    sbox_value = compute_sbox(msg_char)
    for r in range(4):
        for i in range(8):
            H_tmp[i] = H_global[(i+1) % 8] ^ sbox_value
            rotl(H_tmp[i], floor(i/2))
    H_global = H_tmp

# TO CHECK
def compute_sbox(msg_char):
    row = 0b00 ^ (msg_char[0] + msg_char[7])
    column = 0b0000 ^ (msg_char[1] + msg_char[2] + msg_char[3] + msg_char[4])
    sbox_output = des_sbox[row][column]



# ############################################################################ #
# # # # # # # # # # # # # # # # # #   MAIN   # # # # # # # # # # # # # # # # # # 
# ############################################################################ #

# list of ASCII printable characters
alphabet = list(string.printable)
print("alphabet:\n", alphabet)

# list of ASCII printable characters in binary representation
binary_alphabet = [ ascii_to_binary(a) for a in alphabet]
print("binary_alphabet :\n", binary_alphabet)

# message input
print("Insert the message you want to hash:")
msg = input()
print("Message entered. Start hashing...")
msg_list = list(msg)
len = len(msg_list)
print("Length of the message: ", len)

# hash computation 
H_global = H_init
for i in range(len):
    print("Character: ", msg_list[i])
    full_hash(H_global, msg_list[i])

# TODO 


