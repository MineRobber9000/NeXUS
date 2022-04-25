import riff

class CodeChunk(riff.Chunk):
    def __init__(self,code=''):
        if type(code)==str: code=code.encode("utf-8")
        super(CodeChunk,self).__init__("CODE",code)
    def __get_code(self):
        return self.data.decode("utf-8")
    def __set_code(self,code):
        self.data = code.encode("utf-8")
    code = property(__get_code,__set_code)

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
            ret.chunks.append(chunk)
        return ret
