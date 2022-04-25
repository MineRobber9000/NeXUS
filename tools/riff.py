import struct
class Chunk:
    def __init__(self,ckID,data):
        assert type(ckID)==str, "Chunk ID must be string"
        assert len(ckID)==4, "Chunk ID must be 4 characters long"
        self.ckID = ckID
        if type(data)==str: data=data.encode()
        self.data = data
    def encode(self):
        return self.ckID.encode("ascii")+struct.pack("<I",len(self.data))+self.data

class RiffOrListChunk(Chunk):
    def __init__(self,ckID,form,chunks=None):
        if chunks is None: chunks=[]
        assert type(ckID)==str, "Chunk ID must be string"
        assert len(ckID)==4, "Chunk ID must be 4 characters long"
        self.ckID = ckID
        assert type(form)==str, "Form ID must be string"
        assert len(form)==4, "Form ID must be 4 characters long"
        self.form = form
        self.chunks = chunks
    def encode(self):
        data = bytearray()
        for chunk in self.chunks:
            data.extend(chunk.encode())
            if len(data)&1: data.append(b'\x00')
        return self.ckID.encode("ascii")+struct.pack("<I",len(data)+4)+self.form.encode("ascii")+data

def parse_chunk(fp):
    ckID = fp.read(4).decode("ascii")
    if len(ckID)<4: raise EOFError
    size = struct.unpack("<I",fp.read(4))[0]
    if ckID in ("RIFF", "LIST"):
        pos = fp.tell()
        form = fp.read(4).decode("ascii")
        if len(form)<4: raise EOFError
        chunks = []
        while fp.tell()<(pos+size):
            chunks.append(parse_chunk(fp))
        return RiffOrListChunk(ckID,form,chunks)
    else:
        data = fp.read(size)
        if len(data)<size: raise EOFError
        if (fp.tell()&1): fp.read(1)
        return Chunk(ckID,data)

def parse_riff(fp):
    chunk = parse_chunk(fp)
    assert chunk.ckID=="RIFF","RIFF file must contain RIFF chunk at root!"
    return chunk

def parse_riff_file(fp,form=None,form_error=None):
    if form is not None and form_error is None: form_error = "expected RIFF file of form '"+form+"' but got '{}' instead"
    _fp, _close_fp = fp, False
    if type(fp)==str:
        _fp = open(fp,"rb")
        _close_fp = True
    ret = parse_riff(_fp)
    if form is not None: assert ret.form==form, form_error.format(ret.form)
    if _close_fp: _fp.close()
    return ret

def encode_riff_file(fp,riff):
    assert riff.ckID=="RIFF", "RIFF file must contain RIFF chunk at root!"
    _fp, _close_fp = fp, False
    if type(fp)==str:
        _fp = open(fp,"wb")
        _close_fp = True
    _fp.write(riff.encode())
    if _close_fp: _fp.close()
