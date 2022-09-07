import cart, argparse, math
from PIL import Image

round = lambda v: math.floor(v+0.5)

parser = argparse.ArgumentParser(description="Creates a NeXUS ROM/cart from input files.")
parser.add_argument("--graphics",nargs="+",help="Graphics for the cart, stored with sequential IDs from 0 to n.")
parser.add_argument("--binaries",nargs="+",help="Binary resources for the cart, stored with sequential IDs from 0 to n.")
parser.add_argument("code",type=argparse.FileType('r'),help="The code for the cart.")
parser.add_argument("output",type=argparse.FileType('wb'),help="Where the cart should be output.")
args = parser.parse_args()

output = cart.Cart()
output.chunks.append(cart.CodeChunk(args.code.read()))
if args.graphics:
    id = 0
    for image in args.graphics:
        im = Image.open(image).convert("RGBA")
        data = bytearray()
        for y in range(im.height):
            for x in range(im.width):
                r,g,b,a = im.getpixel((x,y))
                rc = round((r/255)*7)
                gc = round((g/255)*7)
                bc = round((b/255)*3)
                data.append((bc<<6)|(gc<<3)|(rc))
        output.chunks.append(cart.GraphicsChunk(id,im.width,im.height,data))
        id+=1
if args.binaries:
    id = 0
    for file in args.binaries:
        with open(file,"rb") as f:
            data = f.read()
        output.chunks.append(cart.BinaryChunk(id,data))
        id+=1
output.to_file(args.output)
