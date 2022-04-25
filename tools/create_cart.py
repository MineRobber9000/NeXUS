import cart, argparse

parser = argparse.ArgumentParser(description="Creates a NeXUS ROM/cart from input files.")
parser.add_argument("code",type=argparse.FileType('r'),help="The code for the cart.")
parser.add_argument("output",type=argparse.FileType('wb'),help="Where the cart should be output.")
args = parser.parse_args()

output = cart.Cart()
output.chunks.append(cart.CodeChunk(args.code.read()))
output.to_file(args.output)
