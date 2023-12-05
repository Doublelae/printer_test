//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <za_blue_printer/za_blue_printer_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) za_blue_printer_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "ZaBluePrinterPlugin");
  za_blue_printer_plugin_register_with_registrar(za_blue_printer_registrar);
}
