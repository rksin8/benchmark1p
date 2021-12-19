# initially reservoir is fully saturated
# Unit MPa instead of Pa, second -> day
# Pa  -> MPa.
# viscosity Pas -> MPa day
# gravity = 10e-6
# youngs_modulus = 5 GPa = 5000 MPa
# Fluid bulk modulus = 2e3 MPa
# Fluid viscosity = 1.1E-3 Pa.s = 1.1E-9 MPa.s =  1.273e-14  MPa.day
# injection rate = 0.02 kg/s/m -> 1728kg/day/m
# Temperature not considered - isothermal case not much effect on outputs 

[Mesh]
  [file_mesh]
    type = FileMeshGenerator
    file = 'model.msh'
  []
[]

[GlobalParams]
  displacements = 'disp_x disp_y'
  PorousFlowDictator = dictator
  biot_coefficient = 1.0
  gravity = '0 -10E-6 0'
[]

[Variables]
  [pp]
  []
  [disp_x]
  []
  [disp_y]
  []
[]

[ICs]
  [pwater]
    type = FunctionIC
    function = p_hydro
    variable = pp
  []
[]

[PorousFlowFullySaturated]
  porepressure = pp
  coupling_type = HydroMechanical
  gravity = '0 -10E-6 0'
  fp = simple_fluid
  eigenstrain_names = 'ini_stress'
  use_displaced_mesh = false
[]

[BCs]
  [top_right]
    type = FunctionDirichletBC
    variable = pp
    function = p_hydro
    boundary = 'top right bottom' # rest no flow except injection_area
  []
  #instead of point source, 0.02kg/m/s injected in 10m face
  [injection]
    type = PorousFlowSink
    variable = pp
    flux_function = -1728 # 0.02 kg/s/m -> kg/m/day in 10m
    boundary = 'injection_area'
  []
  [disp_left]
    type = DirichletBC
    variable = 'disp_x'
    value = 0.0
    boundary = 'left injection_area'
  []
  [disp_bottom_y]
    type = DirichletBC
    variable = 'disp_y'
    value = 0.0
    boundary = 'bottom'
  []
  [top_load]
    type = Pressure
    variable = 'disp_y'
    boundary = 'top'
    component = 1
    factor = 24         #24MPa total stress
    use_displaced_mesh = false
  []
  [load_right]
    type = FunctionNeumannBC
    variable = 'disp_x'
    boundary = 'right'
    function = sigma_h_total  # total insitu stress
    use_displaced_mesh = false
  []
[]


[Modules]
  [FluidProperties]
    [simple_fluid]
      type = SimpleFluidProperties
      bulk_modulus = 2e3  # MPa
      density0 = 1000
      thermal_expansion = 0
      viscosity = 1.2731e-14  # MPa.day
      porepressure_coefficient = 0
      cp = 4194
      cv = 4186
    []
  []
[]

[Materials]
  # [temperature]
  #   type = PorousFlowTemperature
  #   temperature = 310.15 # 35C
  # []
  [porosity_reservoir]
    type = PorousFlowPorosity
    fluid = true
    mechanical = true
    porosity_zero = 0.1
    use_displaced_mesh = false
    ensure_positive = true
    solid_bulk = 2e3
    block = 'matrix'
  []

  [permeability]
    type = PorousFlowPermeabilityKozenyCarman
    poroperm_function = kozeny_carman_phi0
    k0 = 1E-14
    phi0 = 0.1
    n = 2
    m = 2
    block = 'matrix'
  []
  [elasticity_tensor_matrix]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 5000    # MPa
    poissons_ratio = 0.25
    block = 'matrix'
  []

  [strain]
    type = ComputeSmallStrain
    eigenstrain_names = ini_stress
  []
  [stress]
  type = ComputeLinearElasticStress
  []
  [ini_stress]
    type = ComputeEigenstrainFromInitialStress
    eigenstrain_name = ini_stress
    initial_stress = 'sigma_h 0 0  0 sigma_v 0  0 0 sigma_h'
  []
  [density]
    type = GenericConstantMaterial
    prop_names = density
    prop_values = 2400
  []
[]

[Preconditioning]
  [andy]
    type = SMP
    full = true
  []
[]

[Executioner]
  type = Transient
  solve_type = Newton
  petsc_options = '-snes_converged_reason'
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package'
  petsc_options_value = ' lu       superlu_dist'
  line_search = bt
  nl_abs_tol = 1e-3
  l_abs_tol = 1e-4
  l_max_its = 20
  nl_max_its = 20

  start_time = 0
  end_time = 1800  # days
  [TimeStepper]
      type = IterationAdaptiveDT
      dt = 0.1
      growth_factor = 1.2
  []
   dtmax = 20
[]

[Outputs]
  execute_on = 'initial timestep_end'
  file_base = benchmark1p
  exodus = true
  sync_times = '30 365 1000'
  [csvs]
    type = CSV
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]


[Functions]
  [sigma_v]
    type = ParsedFunction
    value = '(2400*10*y - 1000*10*y)/1e6'  # MPa sigma_effective
  []
  [sigma_h]
    type = ParsedFunction
    value = '0.5*(2400*10*y - 1000*10*y)/1e6' # MPa   sigma_effective
  []
  [sigma_h_total]
    type = ParsedFunction
    value = '0.5*(2400*10*y)/1e6' # MPa
  []

  [p_hydro]
      type = ParsedFunction
      value = '-9.81e-3*y + 0.1' # MPa 9.81 MPa/km (-ve y)
  []
[]


[Postprocessors]
  [op1]
    type = PointValue
    point = '0 -1500 0'
    variable = pp
    outputs = 'csvs'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [ux]
    type = PointValue
    point = '500 -1545 0'
    variable = disp_x
    outputs = 'csvs'
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]
# [AuxVariables]
#   [stress_x]
#     order = CONSTANT
#     family = MONOMIAL
#   []
# []
# [AuxKernels]
#   [stress_x]
#     type = RankTwoAux
#     rank_two_tensor = stress
#     variable = stress_x
#     index_i = 0
#     index_j = 0
#   []
# []
