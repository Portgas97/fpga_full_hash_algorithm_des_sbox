# Prototype for the project of Hardware and Embedded Security 2021/2022, Unipi
# Candidates: Francesco Venturini & Pierfrancesco Bigliazzi
# Professors: Sergio Saponara & Luca Crocetti
import string
import random


def ascii_to_binary(ascii_char):
    ascii_char = ascii_char.encode('ascii')
    binascii = int.from_bytes(ascii_char,'big')
    binary_output = bin(binascii)
    return binary_output

alphabet = list(string.printable)
# print("alphabet:\n")
# print(alphabet)
alphabet = [ ascii_to_binary(a) for a in alphabet]
# print("alphabet ASCII:\n")
# print(alphabet)

# H initialization value
H_init = [b'0100',b'1011',b'0111',b'0001',b'1101',b'1111',b'0000',b'0011']

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

# message input
print("Insert the message you want to hash:")
msg = input()
print("Message entered. Start hashing...")

msg_list = list(msg)
print(msg_list)
len = len(msg_list)
print("Length of the message: ", len)

for i in range(len):
    print("Character: ", msg_list[i])

# print('H vector')
# for i in range(len(H_init_value))
#     print(H_init_value[i])

