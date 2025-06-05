# Anatomy of a QEMU driver

qemu/hw/arm/orangepi-zero3.c

```
static void orangepi_init(MachineState *machine)
{
    ...
    h616 = AW_H616(object_new(TYPE_AW_H616)); // Causes allwinner_h616_init to be called.
    ...
    qdev_realize(DEVICE(h616), NULL, &error_abort); // Causes allwinner_h616_realize to be called.
}
```

the orangepi board may depend on things existing in the h616 soc.
anything that is created (init) in the soc must then be realized in the soc too (realize)