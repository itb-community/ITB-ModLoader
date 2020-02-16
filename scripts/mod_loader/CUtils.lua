
local old_c_utilities = package.loaded["itb_c_utilities"]

package.loaded["itb_c_utilities"] = nil
itb_c_utilities = nil

assert(package.loadlib("Cutils.dll", "luaopen_utils"), "cannot find C-Utils dll")()
CUtils = itb_c_utilities

package.loaded["itb_c_utilities"] = old_c_utilities
itb_c_utilities = old_c_utilities
