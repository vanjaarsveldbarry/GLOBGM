# %%
from bokeh.io import output_notebook
output_notebook()
import hvplot.xarray
import panel as pn
from bokeh.models import ColumnDataSource, HoverTool, CustomJS, Div
from bokeh.plotting import figure, show
from bokeh.layouts import row, column
import holoviews as hv
pn.extension()
from cmcrameri import cm
import colorcet as cc
from pathlib import Path
import xarray as xr

SPATIAL_DIMS = ("latitude", "longitude")

def plot_da_interactive(da, cmap="turbo", rasterize=True, clim=(None, None), display=True, width=800, height=600):
    plot = da.hvplot.image(x='longitude', y='latitude', cmap=cmap, hover=True, rasterize=rasterize,
                           width=width, height=height, clim=clim, title=str(da.name))
    panel = pn.panel(plot)
    if display:
        return panel.show()
    else:
        return panel

def plot_ds(ds, title="", cmap="turbo", rasterize=True, clim=(None, None), width=700, height=600):
    """Map of one dataset with a variable selector, plus a selector for every
    non-spatial dim (layer, time, ...) of the chosen variable."""
    ds = ds.rename({k: v for k, v in {"lat": "latitude", "lon": "longitude"}.items() if k in ds.dims})
    variables = [v for v in ds.data_vars if set(SPATIAL_DIMS) <= set(ds[v].dims)]
    variable = pn.widgets.Select(name="variable", options=variables)
    dim_box = pn.Column()
    plot_box = pn.Column()
    dim_widgets = {}  # dim -> (widget, has_coord)

    def current_da():
        da = ds[variable.value]
        for dim, (w, has_coord) in dim_widgets.items():
            da = da.sel({dim: w.value}) if has_coord else da.isel({dim: w.value})
        return da

    def render(*_):
        plot_box[:] = [plot_da_interactive(current_da(), cmap=cmap, rasterize=rasterize, clim=clim,
                                           display=False, width=width, height=height)]

    def rebuild(*_):
        da = ds[variable.value]
        dim_widgets.clear()
        for dim in da.dims:
            if dim in SPATIAL_DIMS:
                continue
            has_coord = dim in da.coords
            vals = da[dim].values if has_coord else range(da.sizes[dim])
            w = pn.widgets.Select(name=dim, options={str(v): v for v in vals})
            w.param.watch(render, "value")
            dim_widgets[dim] = (w, has_coord)
        dim_box[:] = [w for w, _ in dim_widgets.values()]

    variable.param.watch(rebuild, "value")
    variable.param.watch(render, "value")
    rebuild()
    render()
    return pn.Column(f"### {title}", variable, dim_box, plot_box).show()

coords_slice = {"lat": slice(90, -90), "lon": slice(-180, 180)}
# coords_slice = {"lat": slice(32.9, -34.9), "lon": slice(16.3, 32.9)}

# ds = xr.open_zarr(
# "/gpfs/work4/0/prjs1222/chapter3/output/2_calculate_limits/baseflow_limit/z_baseflow_limit.zarr",
# consolidated=False)

ds = xr.open_dataset(
"/gpfs/work4/0/prjs1222/globgm_port/output/run_globgm/post/steady-state/s01_wtd.ss_l2.nc")

plot_ds(ds, title="ds", cmap=cm.batlow, rasterize=True, clim=(None, 0))
# %%