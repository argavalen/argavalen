1. - Command :
P4Runtime sh >>> table_entry["fec_table"](action = "push_mpls").match["ipv4.dstAddr"] = ("10.0.20.0")

- Output :
field_id: 1
lpm {
  value: "\n\000\024\000"
  prefix_len: 32
}

2. - Command :
P4Runtime sh >>> table_entry["fec_table"](action = "push_mpls").action["label"] = ("10")

- Output :
param_id: 1
value: "\n"

3. - Command :
P4Runtime sh >>> table_entry["fec_table"](action = "push_mpls").insert()
"---------------------------------------------------------------------------"
P4RuntimeWriteException                   Traceback (most recent call last)
<ipython-input-19-1086f3781ccf> in <module>
----> 1 table_entry["fec_table"](action = "push_mpls").insert()

/p4runtime-sh/venv/lib/python3.10/site-packages/p4runtime_sh/shell.py in insert(self)
    681             raise NotImplementedError("Insert not supported for {}".format(self._entity_type.name))
    682         logging.debug("Inserting entry")
--> 683         self._write(p4runtime_pb2.Update.INSERT)
    684 
    685     def delete(self):

/p4runtime-sh/venv/lib/python3.10/site-packages/p4runtime_sh/shell.py in _write(self, type_)
    675         update.type = type_
    676         getattr(update.entity, self._entity_type.name).CopyFrom(self._entry)
--> 677         client.write_update(update)
    678 
    679     def insert(self):

/p4runtime-sh/venv/lib/python3.10/site-packages/p4runtime_sh/p4runtime.py in handle(*args, **kwargs)
    122             if e.code() != grpc.StatusCode.UNKNOWN:
    123                 raise e
--> 124             raise P4RuntimeWriteException(e) from None
    125     return handle
    126 

P4RuntimeWriteException: Error(s) during Write:
        * At index 0: INVALID_ARGUMENT, 'Unexpected number of action parameters'
