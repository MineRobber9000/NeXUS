import riff, struct

class CodeChunk(riff.Chunk):
    def __init__(self,code=''):
        if type(code)==str: code=code.encode("utf-8")
        super(CodeChunk,self).__init__("CODE",code)
    def __get_code(self):
        return self.data.decode("utf-8")
    def __set_code(self,code):
        self.data = code.encode("utf-8")
    code = property(__get_code,__set_code)

class GraphicsChunk(riff.Chunk):
    def __init__(self,id=0,width=0,height=0,img_data=b''):
        self.ckID = "GRPH"
        self.id = id
        self.width = width
        self.height = height
        self.img_data = img_data
    @property
    def data(self):
        assert len(self.img_data)==(self.width*self.height), ""
        return struct.pack("<III",self.id,self.width,self.height)+self.img_data
    @classmethod
    def from_data(cls,data):
        id, width, height = struct.unpack("<III",data[:12])
        img_data = data[12:]
        return cls(id,width,height,img_data)

class Cart(riff.RiffOrListChunk):
    def __init__(self,chunks=None):
        super(Cart,self).__init__("RIFF","NXSR",chunks)
    def to_file(self,fp):
        riff.encode_riff_file(fp,self)
    @classmethod
    def from_file(cls,fp):
        generic = riff.parse_riff_file(fp,"NXSR","Expected NeXUS ROM (NXSR), got {} instead")
        ret = cls()
        for chunk in generic.chunks:
            if chunk.ckID=="CODE":
                chunk = CodeChunk(chunk.data)
            elif chunk.ckID=="GRPH":
                chunk = GraphicsChunk.from_data(chunk.data)
            ret.chunks.append(chunk)
        return ret
