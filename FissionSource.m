%> @file  FissionSource.m
%> @brief FissionSource class definition.
% ==============================================================================
%> @brief Defines the isotropic source from fission reactions.
%
%> 
% ==============================================================================
classdef FissionSource < handle
   
    properties (Access = private)
        %> State vectors.
        d_state
        %> Problem mesh.
        d_mesh      
        %> Material definitions.
        d_mat
        %> Vector of \f$ \nu \Sigma_f  \f$ values for dot product.
        d_nu_sigma_f      
        %> Vector \f$ \chi \f$ values for dot product.
        d_chi 
        %> Fission density, \f$  f = \sum_g \nu\Sigma_{f,g} \phi_g \f$.
        d_fission_density   
        %> Fission source, \f$ \textrm{scale} \times f \f$.
        d_fission_source    
        %> Fission source scaling term.
        d_scale = 1.0;   
        d_inv_four_pi = 1.0 / 4.0 / pi;
        %> Are we initialized?
        d_initialized = 0;
    end
    
    methods
       
        % ======================================================================
        %> @brief Class constructor
        %
        %> @param   mesh    Problem mesh.
        %> @param   mat     Material definitions.
        %> @return          Instance of the FissionSource class.
        % ======================================================================
        function obj = FissionSource(state, mesh, mat)
            obj.d_state = state;
            obj.d_mesh  = mesh;
            obj.d_mat   = mat;
        end
        
        % ======================================================================
        %> @brief Initialize the fission source.
        %
        %> Having a separate initialization routine lets us pass around an empty
        %> fission source object, yielding more generic programming.
        % ======================================================================
        function obj = initialize(obj)
            
            % Fission density and source are both one group vectors.
            %obj.d_fission_density = zeros(number_cells(obj.d_mesh), 1);
            obj.d_fission_source  = zeros(number_cells(obj.d_mesh), 1);
            
            % Grab the material map and reshape it to a vector.
            mat = reshape(mesh_map(obj.d_mesh, 'MATERIAL'), ...
                          number_cells(obj.d_mesh), 1);
            
            % Initialize the nu_sigma_f and chi vectors
            obj.d_nu_sigma_f = zeros(number_cells(obj.d_mesh), ...
                                     number_groups(obj.d_mat));
            obj.d_chi        = zeros(number_cells(obj.d_mesh), ...
                                     number_groups(obj.d_mat));
            
            % Loop through all spatial cells (irrespective of dimension).  Note,
            % for large problems with large numbers of groups, this may become 
            % prohibitive.  However, MATLAB loops are slow, so we want to be
            % able to leverage dot products when possible.
            for cell = 1:number_cells(obj.d_mesh)
                for group = 1:number_groups(obj.d_mat)
                    obj.d_nu_sigma_f(cell, group) = ...
                        nu_sigma_f(obj.d_mat, mat(cell), group);
                    obj.d_chi(cell, group) = ...
                        chi(obj.d_mat, mat(cell), group);                    
                end
            end
            
            % Set the fission density to be equal to the thermal nuSigmaF
            obj.d_fission_density = obj.d_nu_sigma_f(:, end);
            % and normalize to unity.
            obj.d_fission_density = obj.d_fission_density / ...
                norm(obj.d_fission_density);
                                 
            % Signal we're ready
            obj.d_initialized = 1;
        end
        
        function y = initialized(obj)
            y = obj.d_initialized;
        end
        
        % ======================================================================
        %> @brief Update the fission density.
        %
        %> The fission source density is defined
        %> \f[
        %>   f = \sum_g \nu\Sigma_{f,g} \phi_g \, .
        %> \f]
        %> This density is updated at the beginning of an outer iteration when a
        %> new (or initial) scalar flux is known.  At this time, a scaling
        %> factor can be set.  Most often, this is based on an updated 
        %> eigenvalue estimate (for reactor problems), or may be any other
        %> arbitrary value as needed for a variety of problems.
        %>
        %> @param   scale   Scaling factor (typically 1/keff)
        % ======================================================================
        function obj = update(obj, scale)
            
            % Set scaling factor (optional)
            if nargin == 1
                obj.d_scale = 1.0;
            else
                obj.d_scale = scale * obj.d_inv_four_pi;
            end
            
            % Update the density.
            for g = 1:number_groups(obj.d_mat)
                % Get the group flux from the state.
                phi = flux(obj.d_state, g);
                % Add the group contribution.
                obj.d_fission_density = obj.d_fission_density + ...
                    phi .* obj.d_nu_sigma_f(:, g);
            end
            
            % Scale the density.
            if obj.d_scale ~= 1.0
                obj.d_fission_density = obj.d_fission_density * obj.d_scale;
            end
            
        end
        
        % ======================================================================
        %> @brief Return the fission source in a group.
        %
        %> The group fission source is just that component of the density
        %> released in  a particular group.  Mathematically, this is just
        %> \f[
        %>   q_{f,g} = \frac{\chi_g}{4\pi k} \sum_g \nu\Sigma_{f,g} \phi_g \, .
        %> \f]
        %> Note, the scaling factor is actually arbitrary.  For 2-D and 3-D, it
        %> is \f$ 4\pi \f$, possibly with the eigenvalue \f$ k \f$.  The client
        %> sets this in \ref update.  
        %>
        %> Note also that this returns a \em discrete source, ready for use in
        %> sweeping.
        %>
        %> @param   g   Group of the source
        %> @return      Source vector
        % ======================================================================
        function q = source(obj, g)
            q = obj.d_fission_density(:) .* obj.d_chi(:, g) * obj.d_scale;   
        end
        
        function f = density(obj)
            f = obj.d_fission_density;
        end
        
    end
    
end