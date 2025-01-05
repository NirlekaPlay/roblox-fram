local chamber_pressure   -- Pressure of the chamber (Pa or Torr)
local chamber_mol         -- Moles of gas in the chamber (mol)
local chamber_volume      -- Volume of the chamber (m³)
local gas_temp            -- Gas temperature (K)
local gas_constant = 8.314 -- Gas constant (J/mol·K)
local gas_mol_mass        -- Molar mass of the gas (kg/mol)
local gas_flow_rate       -- Flow rate of the gas into the chamber (mol/s or m³/s)
local pump_speed          -- Pumping speed (m³/s)
local pump_evacuate_time -- Time to evacuate the chamber (s)

local plasma_density      -- Plasma density (ions/m³)
local electron_density    -- Electron density in the plasma (electrons/m³)
local electron_temp       -- Electron temperature (eV or K)
local plasma_current      -- Current in the plasma (A)
local grid_voltage        -- Voltage across the inner and outer grids (V)
local electron_charge     -- Charge of an electron (C) [1.602 x 10^-19 C]
local ionization_cross_section  -- Ionization cross-section (cm²)
local electron_velocity   -- Electron velocity (m/s)
local ion_charge          -- Ion charge (unitless) [typically 1 for deuterium]

local acceleration_voltage   -- Acceleration voltage (V)
local ion_mass              -- Ion mass (kg) [e.g., deuterium mass]
local ion_velocity          -- Ion velocity (m/s)
local ion_temperature       -- Ion temperature (eV or K)
local ion_energy            -- Ion energy (J or eV)
local reduced_mass          -- Reduced mass of two colliding ions (kg)
local relative_velocity     -- Relative velocity between two ions (m/s)

local fusion_cross_section  -- Fusion cross-section (cm²) [depends on temperature]
local fusion_energy         -- Energy released by the fusion reaction (MeV or J)
local base_fusion_cross_section -- Base fusion cross-section constant (cm²)
local fusion_temperature    -- Plasma temperature (eV)
local fusion_velocity       -- Fusion velocity of ions (m/s)
local relative_velocity_factor -- Factor accounting for relative velocities in fusion

local fusion_rate           -- Fusion rate (reactions per second)
local ion_count             -- Number of ions in the chamber
local fusion_yield          -- Yield of neutrons per fusion event (typically 1 for D-D fusion)

local neutron_yield         -- Total neutron yield (neutrons/s)
local neutron_detector_count -- Number of neutrons detected by a detector
local neutron_detection_cross_section -- Neutron detection cross-section (cm²)
local neutron_production_rate -- Rate at which neutrons are produced (neutrons/s)

local fusion_power          -- Fusion power output (W or J/s)
local fusion_efficiency     -- Efficiency of fusion energy production (percentage)
local input_power           -- Input electrical power (W)
local net_efficiency        -- Net efficiency after accounting for losses