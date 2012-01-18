%> @file  BoundaryCondition.m
%> @brief Boundary condition class definition.
% ==============================================================================
%> @brief Base boundary condition class.
%
%> This contains everything that needs to be known throughout most of the
%> problem.  The scalar flux (and maybe moments later on), an eigenvalue, and
%> boundary fluxes all live here.
% ==============================================================================
classdef BoundaryCondition < handle

    properties (Access = protected) 
        %> Boundary flux object.
        d_boundary
        % Surface identifier.
        d_side = 0 
    end
    
    methods
        
        % ======================================================================
        %> @brief Class constructor
        %>
        %> More detailed description of what the constructor does.
        %>
        %> @param boundary      Boundary flux class.
        %> @param side          Surface identifier.
        %>
        %> @return Instance of the Boundary class.
        % ======================================================================
        function obj = BoundaryCondition(boundary, side)
            obj.d_boundary = boundary;
            obj.d_side = side;
        end

        % ======================================================================
        %> @brief Update the boundary flux.
        % ======================================================================
        obj = update(obj);
        
    end
 
end