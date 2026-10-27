"""Download the monthly 30-arcsecond forcing from the DAG (iRODS zone nluu14p).

SRC holds 244 PCR-GLOBWB clones, each run in three periods
(<clone>/<years>/netcdf/). Fetches the FILES of the PERIODS, kept at their
path relative to SRC under <dst>; files already there at the same size are
skipped.
--list prints what SRC holds and downloads nothing.

Usage: get_1km_forcing.py <dst> [--list]
"""
import json
import ssl
import sys
from pathlib import Path

from irods.session import iRODSSession

ENV = Path.home() / ".irods/irods_environment_DAG.json"
CA = Path.home() / ".irods/cacert.pem"
PASSWORD = "Rp5m3Tt6ssTAuboO-GsZarfuT-dI0gM7"
SRC = "/nluu14p/home/vault-pilot/pcrglobwb_global_30arcsec[1746459966]/original/output/30sec/newDownscale"
FILES = ("discharge_monthAvg_output.nc", "gwRecharge_monthTot_output.nc",
         "totalGroundwaterAbstraction_monthTot_output.nc")
PERIODS = ("1979_1994",)


def main(dst, listing):
    ctx = ssl.create_default_context(purpose=ssl.Purpose.SERVER_AUTH, cafile=CA)
    with iRODSSession(irods_password=PASSWORD, **json.loads(ENV.read_text()), ssl_context=ctx) as s:
        todo = []
        for coll, _, objs in s.collections.get(SRC).walk():
            for o in objs:
                if listing:
                    print(o.path, o.size)
                    continue
                if o.name not in FILES or Path(coll.path).parent.name not in PERIODS:
                    continue
                out = Path(dst) / Path(o.path).relative_to(SRC)
                if not (out.is_file() and out.stat().st_size == o.size):
                    todo.append((o.path, out))
        for i, (src, out) in enumerate(todo, 1):
            out.parent.mkdir(parents=True, exist_ok=True)
            s.data_objects.get(src, str(out), force=True)
            print(f"{i} out of {len(todo)} files", flush=True)


if __name__ == "__main__":
    main(sys.argv[1], "--list" in sys.argv[2:])
