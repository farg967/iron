!> \file
!> \author Chris Bradley
!> \brief This module handles all mesh (node and element) routines.
!>
!> \section LICENSE
!>
!> Version: MPL 1.1/GPL 2.0/LGPL 2.1
!>
!> The contents of this file are subject to the Mozilla Public License
!> Version 1.1 (the "License"); you may not use this file except in
!> compliance with the License. You may obtain a copy of the License at
!> http://www.mozilla.org/MPL/
!>
!> Software distributed under the License is distributed on an "AS IS"
!> basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
!> License for the specific language governing rights and limitations
!> under the License.
!>
!> The Original Code is OpenCMISS
!>
!> The Initial Developer of the Original Code is University of Auckland,
!> Auckland, New Zealand, the University of Oxford, Oxford, United
!> Kingdom and King's College, London, United Kingdom. Portions created
!> by the University of Auckland, the University of Oxford and King's
!> College, London are Copyright (C) 2007-2010 by the University of
!> Auckland, the University of Oxford and King's College, London.
!> All Rights Reserved.
!>
!> Contributor(s):
!>
!> Alternatively, the contents of this file may be used under the terms of
!> either the GNU General Public License Version 2 or later (the "GPL"), or
!> the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
!> in which case the provisions of the GPL or the LGPL are applicable instead
!> of those above. If you wish to allow use of your version of this file only
!> under the terms of either the GPL or the LGPL, and not to allow others to
!> use your version of this file under the terms of the MPL, indicate your
!> decision by deleting the provisions above and replace them with the notice
!> and other provisions required by the GPL or the LGPL. If you do not delete
!> the provisions above, a recipient may use your version of this file under
!> the terms of any one of the MPL, the GPL or the LGPL.
!>

!> This module handles all mesh (node and element) routines.
MODULE MESH_ROUTINES

  USE BaseRoutines
  USE BasisRoutines
  USE BasisAccessRoutines
  USE CmissMPI
  USE CMISS_PARMETIS
  USE ComputationEnvironment
  USE COORDINATE_ROUTINES
  USE DataProjectionAccessRoutines
  USE DOMAIN_MAPPINGS
  USE Kinds
  USE INPUT_OUTPUT
  USE ISO_VARYING_STRING
  USE Lists
  USE MeshAccessRoutines
#ifndef NOMPIMOD
  USE MPI
#endif
  USE NODE_ROUTINES
  USE RegionAccessRoutines
  USE Strings
  USE Trees
  USE Types

#include "macros.h"

  IMPLICIT NONE

#ifdef NOMPIMOD
#include "mpif.h"
#endif

  PRIVATE

  !Module parameters

  !> \addtogroup MESH_ROUTINES_MeshBoundaryTypes MESH_ROUTINES::MeshBoundaryTypes
  !> \brief The types of whether or not a node/element is on a mesh domain boundary.
  !> \see MESH_ROUTINES
  !>@{
  INTEGER(INTG), PARAMETER :: MESH_OFF_DOMAIN_BOUNDARY=0 !<The node/element is not on the mesh domain boundary. \see MESH_ROUTINES_MeshBoundaryTypes,MESH_ROUTINES
  INTEGER(INTG), PARAMETER :: MESH_ON_DOMAIN_BOUNDARY=1 !<The node/element is on the mesh domain boundary. \see MESH_ROUTINES_MeshBoundaryTypes,MESH_ROUTINES
  !>@}

  !> \addtogroup MESH_ROUTINES_DecompositionTypes MESH_ROUTINES::DecompositionTypes
  !> \brief The Decomposition types parameters
  !> \see MESH_ROUTINES
  !>@{
  INTEGER(INTG), PARAMETER :: DECOMPOSITION_ALL_TYPE=1 !<The decomposition contains all elements. \see MESH_ROUTINES_DecompositionTypes,MESH_ROUTINES
  INTEGER(INTG), PARAMETER :: DECOMPOSITION_CALCULATED_TYPE=2 !<The element decomposition is calculated by graph partitioning. \see MESH_ROUTINES_DecompositionTypes,MESH_ROUTINES
  INTEGER(INTG), PARAMETER :: DECOMPOSITION_USER_DEFINED_TYPE=3 !<The user will set the element decomposition. \see MESH_ROUTINES_DecompositionTypes,MESH_ROUTINES
  !>@}


  !Module types

  !Module variables

  !Interfaces

  INTERFACE DECOMPOSITION_TOPOLOGY_ELEMENT_CHECK_EXISTS
    MODULE PROCEDURE DecompositionTopology_ElementCheckExists
  END INTERFACE DECOMPOSITION_TOPOLOGY_ELEMENT_CHECK_EXISTS

  !>Starts the process of creating a mesh
  INTERFACE MESH_CREATE_START
    MODULE PROCEDURE MESH_CREATE_START_INTERFACE
    MODULE PROCEDURE MESH_CREATE_START_REGION
  END INTERFACE !MESH_CREATE_START

  !>Initialises the meshes for a region or interface.
  INTERFACE MESHES_INITIALISE
    MODULE PROCEDURE MESHES_INITIALISE_INTERFACE
    MODULE PROCEDURE MESHES_INITIALISE_REGION
  END INTERFACE !MESHES_INITIALISE

  INTERFACE MeshTopology_ElementCheckExists
    MODULE PROCEDURE MeshTopology_ElementCheckExistsMesh
    MODULE PROCEDURE MeshTopology_ElementCheckExistsMeshElements
  END INTERFACE MeshTopology_ElementCheckExists

  INTERFACE MeshTopology_ElementGet
    MODULE PROCEDURE MeshTopology_ElementGetMeshElements
  END INTERFACE MeshTopology_ElementGet

  INTERFACE MeshTopology_NodeCheckExists
    MODULE PROCEDURE MeshTopology_NodeCheckExistsMesh
    MODULE PROCEDURE MeshTopology_NodeCheckExistsMeshNodes
  END INTERFACE MeshTopology_NodeCheckExists

  INTERFACE MeshTopology_NodeGet
    MODULE PROCEDURE MeshTopology_NodeGetMeshNodes
  END INTERFACE MeshTopology_NodeGet

  PUBLIC DECOMPOSITION_ALL_TYPE,DECOMPOSITION_CALCULATED_TYPE,DECOMPOSITION_USER_DEFINED_TYPE

  PUBLIC MESH_ON_DOMAIN_BOUNDARY,MESH_OFF_DOMAIN_BOUNDARY

  PUBLIC DECOMPOSITIONS_INITIALISE,DECOMPOSITIONS_FINALISE

  PUBLIC DECOMPOSITION_CREATE_START,DECOMPOSITION_CREATE_FINISH

  PUBLIC DECOMPOSITION_DESTROY

  PUBLIC DECOMPOSITION_ELEMENT_DOMAIN_CALCULATE

  PUBLIC DECOMPOSITION_ELEMENT_DOMAIN_GET,DECOMPOSITION_ELEMENT_DOMAIN_SET

  PUBLIC DECOMPOSITION_MESH_COMPONENT_NUMBER_GET,DECOMPOSITION_MESH_COMPONENT_NUMBER_SET

  PUBLIC DECOMPOSITION_NUMBER_OF_DOMAINS_GET,DECOMPOSITION_NUMBER_OF_DOMAINS_SET

  PUBLIC DecompositionTopology_DataPointCheckExists

  PUBLIC DecompositionTopology_DataProjectionCalculate

  PUBLIC DecompositionTopology_ElementCheckExists,DECOMPOSITION_TOPOLOGY_ELEMENT_CHECK_EXISTS

  PUBLIC DecompositionTopology_ElementDataPointLocalNumberGet

  PUBLIC DecompositionTopology_ElementDataPointUserNumberGet

  PUBLIC DecompositionTopology_ElementGet

  PUBLIC DecompositionTopology_NumberOfElementDataPointsGet

  PUBLIC DECOMPOSITION_TYPE_GET,DECOMPOSITION_TYPE_SET

  PUBLIC DECOMPOSITION_NODE_DOMAIN_GET

  PUBLIC DECOMPOSITION_CALCULATE_LINES_SET,DECOMPOSITION_CALCULATE_FACES_SET

  PUBLIC DECOMPOSITION_CALCULATE_CENTROIDS_SET,DECOMPOSITION_CALCULATE_CENTRE_LENGTHS_SET

  PUBLIC DomainTopology_ElementBasisGet

  PUBLIC DOMAIN_TOPOLOGY_NODE_CHECK_EXISTS

  PUBLIC MeshTopology_ElementCheckExists,MeshTopology_NodeCheckExists

  PUBLIC MESH_CREATE_START,MESH_CREATE_FINISH

  PUBLIC MESH_DESTROY

  PUBLIC MESH_NUMBER_OF_COMPONENTS_GET,MESH_NUMBER_OF_COMPONENTS_SET

  PUBLIC MESH_NUMBER_OF_ELEMENTS_GET,MESH_NUMBER_OF_ELEMENTS_SET

  PUBLIC MESH_TOPOLOGY_ELEMENTS_CREATE_START,MESH_TOPOLOGY_ELEMENTS_CREATE_FINISH

  PUBLIC MESH_TOPOLOGY_ELEMENTS_DESTROY

  PUBLIC MESH_TOPOLOGY_ELEMENTS_ELEMENT_BASIS_GET,MESH_TOPOLOGY_ELEMENTS_ELEMENT_BASIS_SET

  PUBLIC MESH_TOPOLOGY_ELEMENTS_ADJACENT_ELEMENT_GET

  PUBLIC MESH_TOPOLOGY_ELEMENTS_ELEMENT_NODES_GET

  PUBLIC MESH_TOPOLOGY_ELEMENTS_ELEMENT_NODES_SET,MeshElements_ElementNodeVersionSet

  PUBLIC MeshTopology_DataPointsCalculateProjection

  PUBLIC MeshTopology_ElementOnBoundaryGet

  PUBLIC MeshElements_ElementUserNumberGet,MeshElements_ElementUserNumberSet

  PUBLIC MeshTopology_ElementsUserNumbersAllSet

  PUBLIC MeshTopology_NodeOnBoundaryGet

  PUBLIC MeshTopology_NodeDerivativesGet

  PUBLIC MeshTopology_NodeNumberOfDerivativesGet

  PUBLIC MeshTopology_NodeNumberOfVersionsGet

  PUBLIC MeshTopology_NodesNumberOfNodesGet

  PUBLIC MeshTopology_NodesDestroy

  PUBLIC MESH_SURROUNDING_ELEMENTS_CALCULATE_SET

  PUBLIC MESH_EMBEDDING_CREATE,MESH_EMBEDDING_SET_CHILD_NODE_POSITION

  PUBLIC MESH_EMBEDDING_SET_GAUSS_POINT_DATA

  PUBLIC MESHES_INITIALISE,MESHES_FINALISE

CONTAINS

  !
  !================================================================================================================================
  !

  !>Finialises a decomposition adjacent element information and deallocates all memory
  SUBROUTINE DECOMPOSITION_ADJACENT_ELEMENT_FINALISE(DECOMPOSITION_ADJACENT_ELEMENT,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_ADJACENT_ELEMENT_TYPE) :: DECOMPOSITION_ADJACENT_ELEMENT !<The decomposition adjacent element to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DECOMPOSITION_ADJACENT_ELEMENT_FINALISE",ERR,ERROR,*999)

    DECOMPOSITION_ADJACENT_ELEMENT%NUMBER_OF_ADJACENT_ELEMENTS=0
    IF(ALLOCATED(DECOMPOSITION_ADJACENT_ELEMENT%ADJACENT_ELEMENTS)) DEALLOCATE(DECOMPOSITION_ADJACENT_ELEMENT%ADJACENT_ELEMENTS)

    EXITS("DECOMPOSITION_ADJACENT_ELEMENT_FINALISE")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_ADJACENT_ELEMENT_FINALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DECOMPOSITION_ADJACENT_ELEMENT_FINALISE

  !
  !================================================================================================================================
  !
  !>Initalises a decomposition adjacent element information.
  SUBROUTINE DECOMPOSITION_ADJACENT_ELEMENT_INITIALISE(DECOMPOSITION_ADJACENT_ELEMENT,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_ADJACENT_ELEMENT_TYPE) :: DECOMPOSITION_ADJACENT_ELEMENT !<The decomposition adjacent element to initialise.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DECOMPOSITION_ADJACENT_ELEMENT_INITIALISE",ERR,ERROR,*999)

    DECOMPOSITION_ADJACENT_ELEMENT%NUMBER_OF_ADJACENT_ELEMENTS=0

    EXITS("DECOMPOSITION_ADJACENT_ELEMENT_INITIALISE")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_ADJACENT_ELEMENT_INITIALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DECOMPOSITION_ADJACENT_ELEMENT_INITIALISE

  !
  !================================================================================================================================
  !
  !>Finishes the creation of a domain decomposition on a given mesh. \see OPENCMISS::Iron::cmfe_DecompositionCreateFinish
  SUBROUTINE DECOMPOSITION_CREATE_FINISH(DECOMPOSITION,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION !<A pointer to the decomposition to finish creating
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: decomposition_no
    TYPE(MESH_TYPE), POINTER :: MESH

    ENTERS("DECOMPOSITION_CREATE_FINISH",ERR,ERROR,*999)

    IF(ASSOCIATED(DECOMPOSITION)) THEN

      !Calculate which elements belong to which domain
      CALL DECOMPOSITION_ELEMENT_DOMAIN_CALCULATE(DECOMPOSITION,ERR,ERROR,*999)
      !Initialise the topology information for this decomposition
      CALL DECOMPOSITION_TOPOLOGY_INITIALISE(DECOMPOSITION,ERR,ERROR,*999)
      !Initialise the domain for this computational node
      CALL DOMAIN_INITIALISE(DECOMPOSITION,ERR,ERROR,*999)
      !Calculate the decomposition topology
      CALL DECOMPOSITION_TOPOLOGY_CALCULATE(DECOMPOSITION,ERR,ERROR,*999)
      DECOMPOSITION%DECOMPOSITION_FINISHED=.TRUE.
      !
    ELSE
      CALL FlagError("Decomposition is not associated.",ERR,ERROR,*999)
    ENDIF

    IF(DIAGNOSTICS1) THEN
      MESH=>DECOMPOSITION%MESH
      IF(ASSOCIATED(MESH)) THEN
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"Mesh = ",MESH%USER_NUMBER,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  Number of decompositions = ", &
          & MESH%DECOMPOSITIONS%NUMBER_OF_DECOMPOSITIONS,ERR,ERROR,*999)
        DO decomposition_no=1,MESH%DECOMPOSITIONS%NUMBER_OF_DECOMPOSITIONS
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  Decomposition number = ",decomposition_no,ERR,ERROR,*999)
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Global number        = ", &
            & MESH%DECOMPOSITIONS%DECOMPOSITIONS(decomposition_no)%PTR%GLOBAL_NUMBER,ERR,ERROR,*999)
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    User number          = ", &
            & MESH%DECOMPOSITIONS%DECOMPOSITIONS(decomposition_no)%PTR%USER_NUMBER,ERR,ERROR,*999)
        ENDDO !decomposition_no
      ELSE
        CALL FlagError("Decomposition mesh is not associated.",ERR,ERROR,*999)
      ENDIF
    ENDIF

    EXITS("DECOMPOSITION_CREATE_FINISH")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_CREATE_FINISH",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_CREATE_FINISH

  !
  !================================================================================================================================
  !

  !>Starts the creation of a domain decomposition for a given mesh. \see OPENCMISS::Iron::cmfe_DecompositionCreateStart
  SUBROUTINE DECOMPOSITION_CREATE_START(USER_NUMBER,MESH,DECOMPOSITION,ERR,ERROR,*)

    !Argument variables
    INTEGER(INTG), INTENT(IN) :: USER_NUMBER !<The user number of the decomposition
    TYPE(MESH_TYPE), POINTER :: MESH !<A pointer to the mesh to decompose
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION !<On return a pointer to the created decomposition. Must not be associated on entry.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: decompositionIdx,dummyErr
    TYPE(VARYING_STRING) :: dummyError,LOCAL_ERROR
    TYPE(DECOMPOSITION_TYPE), POINTER :: newDecomposition
    TYPE(DECOMPOSITION_PTR_TYPE), ALLOCATABLE :: newDecompositions(:)

    NULLIFY(newDecomposition)

    ENTERS("DECOMPOSITION_CREATE_START",ERR,ERROR,*999)

    IF(ASSOCIATED(mesh)) THEN
      IF(mesh%MESH_FINISHED) THEN
        IF(ASSOCIATED(mesh%topology)) THEN
          IF(ASSOCIATED(mesh%decompositions)) THEN
            IF(ASSOCIATED(decomposition)) THEN
              CALL FlagError("Decomposition is already associated.",err,error,*999)
            ELSE
              NULLIFY(decomposition)
              CALL Decomposition_UserNumberFind(USER_NUMBER,MESH,decomposition,ERR,ERROR,*999)
              IF(ASSOCIATED(DECOMPOSITION)) THEN
                LOCAL_ERROR="Decomposition number "//TRIM(NUMBER_TO_VSTRING(USER_NUMBER,"*",ERR,ERROR))// &
                  & " has already been created on mesh number "//TRIM(NUMBER_TO_VSTRING(MESH%USER_NUMBER,"*",ERR,ERROR))//"."
                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
              ELSE
                NULLIFY(newDecomposition)
                CALL Decomposition_Initialise(newDecomposition,err,error,*999)
                !Set default decomposition properties
                newDecomposition%GLOBAL_NUMBER=MESH%DECOMPOSITIONS%NUMBER_OF_DECOMPOSITIONS+1
                newDecomposition%USER_NUMBER=USER_NUMBER
                newDecomposition%DECOMPOSITIONS=>MESH%DECOMPOSITIONS
                newDecomposition%MESH=>MESH
                newDecomposition%region=>mesh%region
                newDecomposition%INTERFACE=>mesh%INTERFACE
                newDecomposition%numberOfDimensions=mesh%NUMBER_OF_DIMENSIONS
                newDecomposition%numberOfComponents=mesh%NUMBER_OF_COMPONENTS
                !By default, the process of decompostion was done on the first mesh components. But the decomposition is the
                !same for all mesh components, since the decomposition is element-based.
                newDecomposition%MESH_COMPONENT_NUMBER=1


                !Set calculate_faces and calculate_lines depending on the dimension
                ! calculate faces should be false for 1D and 2D
                SELECT CASE(newDecomposition%numberOfDimensions)
                CASE(1)
                  newDecomposition%CALCULATE_LINES=.True.
                  newDecomposition%CALCULATE_FACES=.False.
                CASE(2)
                  newDecomposition%CALCULATE_LINES=.True.
                  newDecomposition%CALCULATE_FACES=.False.
                CASE(3)
                  !\todo calculate lines in 3D when needed
                  newDecomposition%CALCULATE_LINES=.False.
                  newDecomposition%CALCULATE_FACES=.True.
                ENDSELECT
                !Default decomposition is all the mesh with one domain.
                newDecomposition%DECOMPOSITION_TYPE=DECOMPOSITION_ALL_TYPE
                newDecomposition%NUMBER_OF_DOMAINS=1
                newDecomposition%numberOfElements=mesh%NUMBER_OF_ELEMENTS
                newDecomposition%CALCULATE_CENTROIDS=.FALSE.
                newDecomposition%CALCULATE_CENTRE_LENGTHS=.FALSE.
                ALLOCATE(newDecomposition%ELEMENT_DOMAIN(MESH%NUMBER_OF_ELEMENTS),STAT=ERR)
                IF(ERR/=0) CALL FlagError("Could not allocate new decomposition element domain.",ERR,ERROR,*999)
                newDecomposition%ELEMENT_DOMAIN=0
                !\todo change this to use move alloc.
                !Add new decomposition into list of decompositions on the mesh
                ALLOCATE(newDecompositions(mesh%decompositions%NUMBER_OF_DECOMPOSITIONS+1),STAT=err)
                IF(ERR/=0) CALL FlagError("Could not allocate new decompositions.",ERR,ERROR,*999)
                DO decompositionIdx=1,MESH%DECOMPOSITIONS%NUMBER_OF_DECOMPOSITIONS
                  newDecompositions(decompositionIdx)%ptr=>mesh%decompositions%decompositions(decompositionIdx)%ptr
                ENDDO !decompositionIdx
                newDecompositions(mesh%decompositions%NUMBER_OF_DECOMPOSITIONS+1)%ptr=>newDecomposition
                CALL MOVE_ALLOC(newDecompositions,mesh%decompositions%decompositions)
                mesh%decompositions%NUMBER_OF_DECOMPOSITIONS=mesh%decompositions%NUMBER_OF_DECOMPOSITIONS+1
                decomposition=>newDecomposition
              ENDIF
            ENDIF
          ELSE
            LOCAL_ERROR="The decompositions on mesh number "//TRIM(NUMBER_TO_VSTRING(MESH%USER_NUMBER,"*",ERR,ERROR))// &
              & " are not associated."
            CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Mesh topology is not associated",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Mesh has not been finished.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Mesh is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_CREATE_START")
    RETURN
999 IF(ASSOCIATED(newDecomposition)) CALL Decomposition_Finalise(newDecomposition,dummyErr,dummyError,*998)
998 IF(ALLOCATED(newDecompositions)) DEALLOCATE(newDecompositions)
    ERRORSEXITS("DECOMPOSITION_CREATE_START",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DECOMPOSITION_CREATE_START

  !
  !================================================================================================================================
  !

  !>Destroys a domain decomposition identified by a user number and deallocates all memory. \see OPENCMISS::Iron::cmfe_DecompositionDestroy
  SUBROUTINE DECOMPOSITION_DESTROY_NUMBER(USER_NUMBER,MESH,ERR,ERROR,*)

    !Argument variables
    INTEGER(INTG), INTENT(IN) :: USER_NUMBER !<The user number of the decomposition to destroy.
    TYPE(MESH_TYPE), POINTER :: MESH !<A pointer to the mesh containing the decomposition.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: decomposition_idx,decomposition_position
    LOGICAL :: FOUND
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    TYPE(DECOMPOSITION_TYPE), POINTER :: decomposition
    TYPE(DECOMPOSITION_PTR_TYPE), ALLOCATABLE :: newDecompositions(:)

    ENTERS("DECOMPOSITION_DESTROY_NUMBER",ERR,ERROR,*999)

    IF(ASSOCIATED(MESH)) THEN
      IF(ASSOCIATED(MESH%DECOMPOSITIONS)) THEN

        !Find the decomposition identified by the user number
        FOUND=.FALSE.
        decomposition_position=0
        DO WHILE(decomposition_position<MESH%DECOMPOSITIONS%NUMBER_OF_DECOMPOSITIONS.AND..NOT.FOUND)
          decomposition_position=decomposition_position+1
          IF(MESH%DECOMPOSITIONS%DECOMPOSITIONS(decomposition_position)%PTR%USER_NUMBER==USER_NUMBER) FOUND=.TRUE.
        ENDDO

        IF(FOUND) THEN

          decomposition=>MESH%DECOMPOSITIONS%DECOMPOSITIONS(decomposition_position)%PTR

          !Finalise the decomposition
          CALL Decomposition_Finalise(decomposition,err,error,*999)

          !Remove the decomposition from the list of decompositions
          IF(MESH%DECOMPOSITIONS%NUMBER_OF_DECOMPOSITIONS>1) THEN
            ALLOCATE(newDecompositions(MESH%DECOMPOSITIONS%NUMBER_OF_DECOMPOSITIONS-1),STAT=ERR)
            IF(ERR/=0) CALL FlagError("Could not allocate new decompositions.",ERR,ERROR,*999)
            DO decomposition_idx=1,MESH%DECOMPOSITIONS%NUMBER_OF_DECOMPOSITIONS
              IF(decomposition_idx<decomposition_position) THEN
                newDecompositions(decomposition_idx)%ptr=>mesh%DECOMPOSITIONS%DECOMPOSITIONS(decomposition_idx)%PTR
              ELSE IF(decomposition_idx>decomposition_position) THEN
                MESH%DECOMPOSITIONS%DECOMPOSITIONS(decomposition_idx)%PTR%GLOBAL_NUMBER= &
                  & MESH%DECOMPOSITIONS%DECOMPOSITIONS(decomposition_idx)%PTR%GLOBAL_NUMBER-1
                newDecompositions(decomposition_idx-1)%PTR=>MESH%DECOMPOSITIONS%DECOMPOSITIONS(decomposition_idx)%PTR
              ENDIF
            ENDDO !decomposition_idx
            CALL MOVE_ALLOC(newDecompositions,mesh%decompositions%decompositions)
            MESH%DECOMPOSITIONS%NUMBER_OF_DECOMPOSITIONS=MESH%DECOMPOSITIONS%NUMBER_OF_DECOMPOSITIONS-1
          ELSE
            DEALLOCATE(MESH%DECOMPOSITIONS%DECOMPOSITIONS)
            MESH%DECOMPOSITIONS%NUMBER_OF_DECOMPOSITIONS=0
          ENDIF

        ELSE
          LOCAL_ERROR="Decomposition number "//TRIM(NUMBER_TO_VSTRING(USER_NUMBER,"*",ERR,ERROR))// &
            & " has not been created on mesh number "//TRIM(NUMBER_TO_VSTRING(MESH%USER_NUMBER,"*",ERR,ERROR))//"."
          CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
        ENDIF
      ELSE
        LOCAL_ERROR="The decompositions on mesh number "//TRIM(NUMBER_TO_VSTRING(MESH%USER_NUMBER,"*",ERR,ERROR))// &
          & " are not associated."
        CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Mesh is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_DESTROY_NUMBER")
    RETURN
999 IF(ALLOCATED(newDecompositions)) DEALLOCATE(newDecompositions)
    ERRORSEXITS("DECOMPOSITION_DESTROY_NUMBER",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DECOMPOSITION_DESTROY_NUMBER

  !
  !================================================================================================================================
  !

  !>Destroys a domain decomposition identified by an object and deallocates all memory. \see OPENCMISS::Iron::cmfe_DecompositionDestroy
  SUBROUTINE DECOMPOSITION_DESTROY(DECOMPOSITION,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION !<The decomposition to destroy.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: decomposition_idx,decomposition_position
    LOGICAL :: FOUND
    TYPE(MESH_TYPE), POINTER :: MESH !
    TYPE(DECOMPOSITION_PTR_TYPE), ALLOCATABLE :: newDecompositions(:)
    TYPE(DECOMPOSITIONS_TYPE), POINTER :: decompositions

    ENTERS("DECOMPOSITION_DESTROY",ERR,ERROR,*999)

    IF(ASSOCIATED(DECOMPOSITION)) THEN
      DECOMPOSITIONS=>DECOMPOSITION%DECOMPOSITIONS
      IF(ASSOCIATED(DECOMPOSITIONS)) THEN
        mesh=>decomposition%mesh
        IF(ASSOCIATED(mesh)) THEN
          !Find the decomposition identified by the user number
          FOUND=.FALSE.
          decomposition_position=0
          DO WHILE(decomposition_position<MESH%DECOMPOSITIONS%NUMBER_OF_DECOMPOSITIONS.AND..NOT.FOUND)
            decomposition_position=decomposition_position+1
            IF(MESH%DECOMPOSITIONS%DECOMPOSITIONS(decomposition_position)%PTR%USER_NUMBER==DECOMPOSITION%USER_NUMBER) FOUND=.TRUE.
          ENDDO

          !Finalise the decomposition
          CALL Decomposition_Finalise(decomposition,err,error,*999)

          !Remove the decomposition from the list of decompositions
          IF(DECOMPOSITIONS%NUMBER_OF_DECOMPOSITIONS>1) THEN
            ALLOCATE(newDecompositions(DECOMPOSITIONS%NUMBER_OF_DECOMPOSITIONS-1),STAT=ERR)
            IF(ERR/=0) CALL FlagError("Could not allocate new decompositions.",ERR,ERROR,*999)
            DO decomposition_idx=1,DECOMPOSITIONS%NUMBER_OF_DECOMPOSITIONS
              IF(decomposition_idx<decomposition_position) THEN
                newDecompositions(decomposition_idx)%PTR=>DECOMPOSITIONS%DECOMPOSITIONS(decomposition_idx)%PTR
              ELSE IF(decomposition_idx>decomposition_position) THEN
                DECOMPOSITIONS%DECOMPOSITIONS(decomposition_idx)%PTR%GLOBAL_NUMBER= &
                  & DECOMPOSITIONS%DECOMPOSITIONS(decomposition_idx)%PTR%GLOBAL_NUMBER-1
                newDecompositions(decomposition_idx-1)%PTR=>DECOMPOSITIONS%DECOMPOSITIONS(decomposition_idx)%PTR
              ENDIF
            ENDDO !decomposition_idx
            CALL MOVE_ALLOC(newDecompositions,DECOMPOSITIONS%DECOMPOSITIONS)
            DECOMPOSITIONS%NUMBER_OF_DECOMPOSITIONS=DECOMPOSITIONS%NUMBER_OF_DECOMPOSITIONS-1
          ELSE
            DEALLOCATE(DECOMPOSITIONS%DECOMPOSITIONS)
            DECOMPOSITIONS%NUMBER_OF_DECOMPOSITIONS=0
          ENDIF
        ELSE
          CALL FlagError("Decomposition mesh is not associated.",err,error,*999)
        ENDIF
      ELSE
        CALL FlagError("Decomposition decompositions is not associated.",ERR,ERROR,*999)
       ENDIF
    ELSE
      CALL FlagError("Decompositions is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_DESTROY")
    RETURN
999 IF(ALLOCATED(newDecompositions)) DEALLOCATE(newDecompositions)
    ERRORSEXITS("DECOMPOSITION_DESTROY",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_DESTROY

  !
  !================================================================================================================================
  !

  !>Calculates the element domains for a decomposition of a mesh. \see OPENCMISS::Iron::cmfe_DecompositionElementDomainCalculate
  SUBROUTINE DECOMPOSITION_ELEMENT_DOMAIN_CALCULATE(DECOMPOSITION,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION !<A pointer to the decomposition to calculate the element domains for.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: number_elem_indicies,elem_index,elem_count,ne,nn,my_computational_node_number,number_computational_nodes, &
      & no_computational_node,ELEMENT_START,ELEMENT_STOP,MY_ELEMENT_START,MY_ELEMENT_STOP,NUMBER_OF_ELEMENTS, &
      & MY_NUMBER_OF_ELEMENTS,MPI_IERROR,MAX_NUMBER_ELEMENTS_PER_NODE,component_idx,minNumberXi
    INTEGER(INTG), ALLOCATABLE :: ELEMENT_COUNT(:),ELEMENT_PTR(:),ELEMENT_INDICIES(:),ELEMENT_DISTANCE(:),DISPLACEMENTS(:), &
      & RECEIVE_COUNTS(:)
    INTEGER(INTG) :: ELEMENT_WEIGHT(1),WEIGHT_FLAG,NUMBER_FLAG,NUMBER_OF_CONSTRAINTS, &
      & NUMBER_OF_COMMON_NODES,PARMETIS_OPTIONS(0:2)
    !ParMETIS now has double for these
    !REAL(SP) :: UBVEC(1)
    !REAL(SP), ALLOCATABLE :: TPWGTS(:)
    REAL(DP) :: UBVEC(1)
    REAL(DP), ALLOCATABLE :: TPWGTS(:)
    REAL(DP) :: NUMBER_ELEMENTS_PER_NODE
    TYPE(BASIS_TYPE), POINTER :: BASIS
    TYPE(MESH_TYPE), POINTER :: MESH
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("DECOMPOSITION_ELEMENT_DOMAIN_CALCULATE",ERR,ERROR,*999)

    IF(ASSOCIATED(DECOMPOSITION)) THEN
      IF(ASSOCIATED(DECOMPOSITION%MESH)) THEN
        MESH=>DECOMPOSITION%MESH
        IF(ASSOCIATED(MESH%TOPOLOGY)) THEN

          component_idx=DECOMPOSITION%MESH_COMPONENT_NUMBER

          number_computational_nodes=ComputationalEnvironment_NumberOfNodesGet(ERR,ERROR)
          IF(ERR/=0) GOTO 999
          my_computational_node_number=ComputationalEnvironment_NodeNumberGet(ERR,ERROR)
          IF(ERR/=0) GOTO 999

          SELECT CASE(DECOMPOSITION%DECOMPOSITION_TYPE)
          CASE(DECOMPOSITION_ALL_TYPE)
            !Do nothing. Decomposition checked below.
           CASE(DECOMPOSITION_CALCULATED_TYPE)
            !Calculate the general decomposition

            IF(DECOMPOSITION%NUMBER_OF_DOMAINS==1) THEN
              DECOMPOSITION%ELEMENT_DOMAIN=0
            ELSE
              number_computational_nodes=ComputationalEnvironment_NumberOfNodesGet(ERR,ERROR)
              IF(ERR/=0) GOTO 999

              NUMBER_ELEMENTS_PER_NODE=REAL(MESH%NUMBER_OF_ELEMENTS,DP)/REAL(number_computational_nodes,DP)
              ELEMENT_START=1
              ELEMENT_STOP=0
              MAX_NUMBER_ELEMENTS_PER_NODE=-1
              ALLOCATE(RECEIVE_COUNTS(0:number_computational_nodes-1),STAT=ERR)
              IF(ERR/=0) CALL FlagError("Could not allocate recieve counts.",ERR,ERROR,*999)
              ALLOCATE(DISPLACEMENTS(0:number_computational_nodes-1),STAT=ERR)
              IF(ERR/=0) CALL FlagError("Could not allocate displacements.",ERR,ERROR,*999)
              ALLOCATE(ELEMENT_DISTANCE(0:number_computational_nodes),STAT=ERR)
              IF(ERR/=0) CALL FlagError("Could not allocate element distance.",ERR,ERROR,*999)
              ELEMENT_DISTANCE(0)=0
              DO no_computational_node=0,number_computational_nodes-1
                ELEMENT_START=ELEMENT_STOP+1
                IF(no_computational_node==number_computational_nodes-1) THEN
                  ELEMENT_STOP=MESH%NUMBER_OF_ELEMENTS
                ELSE
                  ELEMENT_STOP=ELEMENT_START+NINT(NUMBER_ELEMENTS_PER_NODE,INTG)-1
                ENDIF
                IF((number_computational_nodes-1-no_computational_node)>(MESH%NUMBER_OF_ELEMENTS-ELEMENT_STOP)) &
                  & ELEMENT_STOP=MESH%NUMBER_OF_ELEMENTS-(number_computational_nodes-1-no_computational_node)
                IF(ELEMENT_START>MESH%NUMBER_OF_ELEMENTS) ELEMENT_START=MESH%NUMBER_OF_ELEMENTS
                IF(ELEMENT_STOP>MESH%NUMBER_OF_ELEMENTS) ELEMENT_STOP=MESH%NUMBER_OF_ELEMENTS
                DISPLACEMENTS(no_computational_node)=ELEMENT_START-1
                ELEMENT_DISTANCE(no_computational_node+1)=ELEMENT_STOP !C numbering
                NUMBER_OF_ELEMENTS=ELEMENT_STOP-ELEMENT_START+1
                RECEIVE_COUNTS(no_computational_node)=NUMBER_OF_ELEMENTS
                IF(NUMBER_OF_ELEMENTS>MAX_NUMBER_ELEMENTS_PER_NODE) MAX_NUMBER_ELEMENTS_PER_NODE=NUMBER_OF_ELEMENTS
                IF(no_computational_node==my_computational_node_number) THEN
                  MY_ELEMENT_START=ELEMENT_START
                  MY_ELEMENT_STOP=ELEMENT_STOP
                  MY_NUMBER_OF_ELEMENTS=ELEMENT_STOP-ELEMENT_START+1
                  number_elem_indicies=0
                  DO ne=MY_ELEMENT_START,MY_ELEMENT_STOP
                    BASIS=>MESH%TOPOLOGY(component_idx)%PTR%ELEMENTS%ELEMENTS(ne)%BASIS
                    number_elem_indicies=number_elem_indicies+BASIS%NUMBER_OF_NODES
                  ENDDO !ne
                ENDIF
              ENDDO !no_computational_node

              ALLOCATE(ELEMENT_PTR(0:MY_NUMBER_OF_ELEMENTS),STAT=ERR)
              IF(ERR/=0) CALL FlagError("Could not allocate element pointer list.",ERR,ERROR,*999)
              ALLOCATE(ELEMENT_INDICIES(0:number_elem_indicies-1),STAT=ERR)
              IF(ERR/=0) CALL FlagError("Could not allocate element indicies list.",ERR,ERROR,*999)
              ALLOCATE(TPWGTS(1:DECOMPOSITION%NUMBER_OF_DOMAINS),STAT=ERR)
              IF(ERR/=0) CALL FlagError("Could not allocate tpwgts.",ERR,ERROR,*999)
              elem_index=0
              elem_count=0
              ELEMENT_PTR(0)=0
              minNumberXi=99999
              DO ne=MY_ELEMENT_START,MY_ELEMENT_STOP
                elem_count=elem_count+1
                BASIS=>MESH%TOPOLOGY(component_idx)%PTR%ELEMENTS%ELEMENTS(ne)%BASIS
                IF(BASIS%NUMBER_OF_XI<minNumberXi) minNumberXi=BASIS%NUMBER_OF_XI
                DO nn=1,BASIS%NUMBER_OF_NODES
                  ELEMENT_INDICIES(elem_index)=MESH%TOPOLOGY(component_idx)%PTR%ELEMENTS%ELEMENTS(ne)% &
                    & MESH_ELEMENT_NODES(nn)-1 !C numbering
                  elem_index=elem_index+1
                ENDDO !nn
                ELEMENT_PTR(elem_count)=elem_index !C numbering
              ENDDO !ne

              !Set up ParMETIS variables
              WEIGHT_FLAG=0 !No weights
              ELEMENT_WEIGHT(1)=1 !Isn't used due to weight flag
              NUMBER_FLAG=0 !C Numbering as there is a bug with Fortran numbering
              NUMBER_OF_CONSTRAINTS=1
              IF(minNumberXi==1) THEN
                NUMBER_OF_COMMON_NODES=1
              ELSE
                NUMBER_OF_COMMON_NODES=2
              ENDIF
              !ParMETIS now has doule precision for these
              !TPWGTS=1.0_SP/REAL(DECOMPOSITION%NUMBER_OF_DOMAINS,SP)
              !UBVEC=1.05_SP
              TPWGTS=1.0_DP/REAL(DECOMPOSITION%NUMBER_OF_DOMAINS,DP)
              UBVEC=1.05_DP
              PARMETIS_OPTIONS(0)=1 !If zero, defaults are used, otherwise next two values are used
              PARMETIS_OPTIONS(1)=7 !Level of information to output
              PARMETIS_OPTIONS(2)=cmissRandomSeeds(1) !Seed for random number generator

              !Call ParMETIS to calculate the partitioning of the mesh graph.
              CALL PARMETIS_PARTMESHKWAY(ELEMENT_DISTANCE,ELEMENT_PTR,ELEMENT_INDICIES,ELEMENT_WEIGHT,WEIGHT_FLAG,NUMBER_FLAG, &
                & NUMBER_OF_CONSTRAINTS,NUMBER_OF_COMMON_NODES,DECOMPOSITION%NUMBER_OF_DOMAINS,TPWGTS,UBVEC,PARMETIS_OPTIONS, &
                & DECOMPOSITION%NUMBER_OF_EDGES_CUT,DECOMPOSITION%ELEMENT_DOMAIN(DISPLACEMENTS(my_computational_node_number)+1:), &
                & computationalEnvironment%mpiCommunicator,ERR,ERROR,*999)

              !Transfer all the element domain information to the other computational nodes so that each rank has all the info
              IF(number_computational_nodes>1) THEN
                !This should work on a single processor but doesn't for mpich2 under windows. Maybe a bug? Avoid for now.
                CALL MPI_ALLGATHERV(MPI_IN_PLACE,MAX_NUMBER_ELEMENTS_PER_NODE,MPI_INTEGER,DECOMPOSITION%ELEMENT_DOMAIN, &
                  & RECEIVE_COUNTS,DISPLACEMENTS,MPI_INTEGER,computationalEnvironment%mpiCommunicator,MPI_IERROR)
                CALL MPI_ERROR_CHECK("MPI_ALLGATHERV",MPI_IERROR,ERR,ERROR,*999)
              ENDIF

              DEALLOCATE(DISPLACEMENTS)
              DEALLOCATE(RECEIVE_COUNTS)
              DEALLOCATE(ELEMENT_DISTANCE)
              DEALLOCATE(ELEMENT_PTR)
              DEALLOCATE(ELEMENT_INDICIES)
              DEALLOCATE(TPWGTS)

            ENDIF

          CASE(DECOMPOSITION_USER_DEFINED_TYPE)
            !Do nothing. Decomposition checked below.
          CASE DEFAULT
            CALL FlagError("Invalid domain decomposition type.",ERR,ERROR,*999)
          END SELECT

          !Check decomposition and check that each domain has an element in it.
          ALLOCATE(ELEMENT_COUNT(0:number_computational_nodes-1),STAT=ERR)
          IF(ERR/=0) CALL FlagError("Could not allocate element count.",ERR,ERROR,*999)
          ELEMENT_COUNT=0
          DO elem_index=1,MESH%NUMBER_OF_ELEMENTS
            no_computational_node=DECOMPOSITION%ELEMENT_DOMAIN(elem_index)
            IF(no_computational_node>=0.AND.no_computational_node<number_computational_nodes) THEN
              ELEMENT_COUNT(no_computational_node)=ELEMENT_COUNT(no_computational_node)+1
            ELSE
              LOCAL_ERROR="The computational node number of "//TRIM(NUMBER_TO_VSTRING(no_computational_node,"*",ERR,ERROR))// &
                & " for element number "//TRIM(NUMBER_TO_VSTRING(elem_index,"*",ERR,ERROR))// &
                & " is invalid. The computational node number must be between 0 and "// &
                & TRIM(NUMBER_TO_VSTRING(number_computational_nodes-1,"*",ERR,ERROR))//"."
              CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
            ENDIF
          ENDDO !elem_index
          DO no_computational_node=0,number_computational_nodes-1
            IF(ELEMENT_COUNT(no_computational_node)==0) THEN
              LOCAL_ERROR="Invalid decomposition. There are no elements in computational node "// &
                & TRIM(NUMBER_TO_VSTRING(no_computational_node,"*",ERR,ERROR))//"."
              CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
            ENDIF
          ENDDO !no_computational_node
          DEALLOCATE(ELEMENT_COUNT)

        ELSE
          CALL FlagError("Decomposition mesh topology is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Decomposition mesh is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Decomposition is not associated.",ERR,ERROR,*999)
    ENDIF

    IF(DIAGNOSTICS1) THEN
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"Decomposition for mesh number ",DECOMPOSITION%MESH%USER_NUMBER, &
        & ERR,ERROR,*999)
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  Number of domains = ", DECOMPOSITION%NUMBER_OF_DOMAINS, &
        & ERR,ERROR,*999)
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Element domains:",ERR,ERROR,*999)
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Decomposition type = ", DECOMPOSITION%DECOMPOSITION_TYPE, &
        & ERR,ERROR,*999)
      IF(DECOMPOSITION%DECOMPOSITION_TYPE==DECOMPOSITION_CALCULATED_TYPE) THEN
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Number of edges cut = ",DECOMPOSITION%NUMBER_OF_EDGES_CUT, &
          & ERR,ERROR,*999)
      ENDIF
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Number of elements = ",DECOMPOSITION%numberOfElements, &
        & ERR,ERROR,*999)
      DO ne=1,DECOMPOSITION%numberOfElements
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Element = ",ne,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"        Domain = ",DECOMPOSITION%ELEMENT_DOMAIN(ne), &
          & ERR,ERROR,*999)
      ENDDO !ne
    ENDIF

    EXITS("DECOMPOSITION_ELEMENT_DOMAIN_CALCULATE")
    RETURN
999 IF(ALLOCATED(RECEIVE_COUNTS)) DEALLOCATE(RECEIVE_COUNTS)
    IF(ALLOCATED(DISPLACEMENTS)) DEALLOCATE(DISPLACEMENTS)
    IF(ALLOCATED(ELEMENT_DISTANCE)) DEALLOCATE(ELEMENT_DISTANCE)
    IF(ALLOCATED(ELEMENT_PTR)) DEALLOCATE(ELEMENT_PTR)
    IF(ALLOCATED(ELEMENT_INDICIES)) DEALLOCATE(ELEMENT_INDICIES)
    IF(ALLOCATED(TPWGTS)) DEALLOCATE(TPWGTS)
    ERRORSEXITS("DECOMPOSITION_ELEMENT_DOMAIN_CALCULATE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DECOMPOSITION_ELEMENT_DOMAIN_CALCULATE

  !
  !================================================================================================================================
  !

  !>Gets the domain for a given element in a decomposition of a mesh. \todo should be able to specify lists of elements. \see OPENCMISS::Iron::cmfe_DecompositionElementDomainGet
  SUBROUTINE DECOMPOSITION_ELEMENT_DOMAIN_GET(DECOMPOSITION,USER_ELEMENT_NUMBER,DOMAIN_NUMBER,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION !<A pointer to the decomposition to set the element domain for
    INTEGER(INTG), INTENT(IN) :: USER_ELEMENT_NUMBER !<The user element number to set the domain for.
    INTEGER(INTG), INTENT(OUT) :: DOMAIN_NUMBER !<On return, the domain of the global element.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables`
    TYPE(MESH_TYPE), POINTER :: MESH
    TYPE(MeshComponentTopologyType), POINTER :: MESH_TOPOLOGY
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    INTEGER(INTG) :: GLOBAL_ELEMENT_NUMBER
    TYPE(TREE_NODE_TYPE), POINTER :: TREE_NODE
    TYPE(MeshElementsType), POINTER :: MESH_ELEMENTS


    ENTERS("DECOMPOSITION_ELEMENT_DOMAIN_GET",ERR,ERROR,*999)

    GLOBAL_ELEMENT_NUMBER=0
    IF(ASSOCIATED(DECOMPOSITION)) THEN
      IF(DECOMPOSITION%DECOMPOSITION_FINISHED) THEN
        MESH=>DECOMPOSITION%MESH
        IF(ASSOCIATED(MESH)) THEN
          MESH_TOPOLOGY=>MESH%TOPOLOGY(DECOMPOSITION%MESH_COMPONENT_NUMBER)%PTR
          IF(ASSOCIATED(MESH_TOPOLOGY)) THEN
            MESH_ELEMENTS=>MESH_TOPOLOGY%ELEMENTS
            IF(ASSOCIATED(MESH_ELEMENTS)) THEN
              NULLIFY(TREE_NODE)
              CALL TREE_SEARCH(MESH_ELEMENTS%ELEMENTS_TREE,USER_ELEMENT_NUMBER,TREE_NODE,ERR,ERROR,*999)
              IF(ASSOCIATED(TREE_NODE)) THEN
                CALL TREE_NODE_VALUE_GET(MESH_ELEMENTS%ELEMENTS_TREE,TREE_NODE,GLOBAL_ELEMENT_NUMBER,ERR,ERROR,*999)
                IF(GLOBAL_ELEMENT_NUMBER>0.AND.GLOBAL_ELEMENT_NUMBER<=MESH_TOPOLOGY%ELEMENTS%NUMBER_OF_ELEMENTS) THEN
                  DOMAIN_NUMBER=DECOMPOSITION%ELEMENT_DOMAIN(GLOBAL_ELEMENT_NUMBER)
                ELSE
                  LOCAL_ERROR="Global element number found "//TRIM(NUMBER_TO_VSTRING(GLOBAL_ELEMENT_NUMBER,"*",ERR,ERROR))// &
                    & " is invalid. The limits are 1 to "// &
                    & TRIM(NUMBER_TO_VSTRING(MESH_TOPOLOGY%ELEMENTS%NUMBER_OF_ELEMENTS,"*",ERR,ERROR))//"."
                  CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                ENDIF
              ELSE
                LOCAL_ERROR="Decomposition mesh element corresponding to user element number "// &
                  & TRIM(NumberToVString(USER_ELEMENT_NUMBER,"*",err,error))//" is not found."
                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FlagError("Decomposition mesh elements are not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Decomposition mesh topology is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Decomposition mesh is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Decomposition has not been finished.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Decomposition is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_ELEMENT_DOMAIN_GET")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_ELEMENT_DOMAIN_GET",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_ELEMENT_DOMAIN_GET

  !
  !================================================================================================================================
  !

  !>Sets the domain for a given element in a decomposition of a mesh. \todo move to user number, should be able to specify lists of elements. \see OPENCMISS::Iron::cmfe_DecompositionElementDomainSet
  SUBROUTINE DECOMPOSITION_ELEMENT_DOMAIN_SET(DECOMPOSITION,GLOBAL_ELEMENT_NUMBER,DOMAIN_NUMBER,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION !<A pointer to the decomposition to set the element domain for
    INTEGER(INTG), INTENT(IN) :: GLOBAL_ELEMENT_NUMBER !<The global element number to set the domain for.
    INTEGER(INTG), INTENT(IN) :: DOMAIN_NUMBER !<The domain of the global element.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: number_computational_nodes
    TYPE(MESH_TYPE), POINTER :: MESH
    TYPE(MeshComponentTopologyType), POINTER :: MESH_TOPOLOGY
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("DECOMPOSITION_ELEMENT_DOMAIN_SET",ERR,ERROR,*999)

!!TODO: interface should specify user element number ???

    IF(ASSOCIATED(DECOMPOSITION)) THEN
      IF(DECOMPOSITION%DECOMPOSITION_FINISHED) THEN
        CALL FlagError("Decomposition has been finished.",ERR,ERROR,*999)
      ELSE
        MESH=>DECOMPOSITION%MESH
        IF(ASSOCIATED(MESH)) THEN
          MESH_TOPOLOGY=>MESH%TOPOLOGY(DECOMPOSITION%MESH_COMPONENT_NUMBER)%PTR
          IF(ASSOCIATED(MESH_TOPOLOGY)) THEN
            IF(GLOBAL_ELEMENT_NUMBER>0.AND.GLOBAL_ELEMENT_NUMBER<=MESH_TOPOLOGY%ELEMENTS%NUMBER_OF_ELEMENTS) THEN
              number_computational_nodes=ComputationalEnvironment_NumberOfNodesGet(ERR,ERROR)
              IF(ERR/=0) GOTO 999
              IF(DOMAIN_NUMBER>=0.AND.DOMAIN_NUMBER<number_computational_nodes) THEN
                DECOMPOSITION%ELEMENT_DOMAIN(GLOBAL_ELEMENT_NUMBER)=DOMAIN_NUMBER
              ELSE
                LOCAL_ERROR="Domain number "//TRIM(NUMBER_TO_VSTRING(DOMAIN_NUMBER,"*",ERR,ERROR))// &
                  & " is invalid. The limits are 0 to "//TRIM(NUMBER_TO_VSTRING(number_computational_nodes,"*",ERR,ERROR))//"."
                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
              ENDIF
            ELSE
              LOCAL_ERROR="Global element number "//TRIM(NUMBER_TO_VSTRING(GLOBAL_ELEMENT_NUMBER,"*",ERR,ERROR))// &
                & " is invalid. The limits are 1 to "// &
                & TRIM(NUMBER_TO_VSTRING(MESH_TOPOLOGY%ELEMENTS%NUMBER_OF_ELEMENTS,"*",ERR,ERROR))//"."
              CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Decomposition mesh topology is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Decomposition mesh is not associated.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Decomposition is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_ELEMENT_DOMAIN_SET")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_ELEMENT_DOMAIN_SET",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_ELEMENT_DOMAIN_SET

  !
  !================================================================================================================================
  !

  !>Finalises a decomposition and deallocates all memory.
  SUBROUTINE Decomposition_Finalise(decomposition,err,error,*)

    !Argument variables
    TYPE(DECOMPOSITION_TYPE), POINTER :: decomposition !<A pointer to the decomposition to finalise
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables

    ENTERS("Decomposition_Finalise",err,error,*999)


    IF(ASSOCIATED(decomposition)) THEN
      !Destroy all the decomposition components
      IF(ALLOCATED(decomposition%ELEMENT_DOMAIN)) DEALLOCATE(decomposition%ELEMENT_DOMAIN)
      CALL DECOMPOSITION_TOPOLOGY_FINALISE(decomposition,err,error,*999)
      CALL DOMAIN_FINALISE(decomposition,err,error,*999)
      DEALLOCATE(decomposition)
    ENDIF

    EXITS("Decomposition_Finalise")
    RETURN
999 ERRORSEXITS("Decomposition_Finalise",err,error)
    RETURN 1

  END SUBROUTINE Decomposition_Finalise

  !
  !================================================================================================================================
  !

  !>Inintialises a decomposition and allocates all memory.
  SUBROUTINE Decomposition_Initialise(decomposition,err,error,*)

    !Argument variables
    TYPE(DECOMPOSITION_TYPE), POINTER :: decomposition !<A pointer to the decomposition to initialise. Must not be allocated on entry.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: dummyErr
    TYPE(VARYING_STRING) :: dummyError

    ENTERS("Decomposition_Initialise",err,error,*998)

    IF(ASSOCIATED(decomposition)) THEN
      CALL FlagError("Decomposition is already associated.",err,error,*998)
    ELSE
      ALLOCATE(decomposition,STAT=err)
      IF(err/=0) CALL FlagError("Could not allocate decomposition.",err,error,*999)
      decomposition%GLOBAL_NUMBER=0
      decomposition%USER_NUMBER=0
      decomposition%DECOMPOSITION_FINISHED=.FALSE.
      NULLIFY(decomposition%decompositions)
      NULLIFY(decomposition%mesh)
      NULLIFY(decomposition%region)
      NULLIFY(decomposition%INTERFACE)
      decomposition%numberOfDimensions=0
      decomposition%numberOfComponents=0
      decomposition%DECOMPOSITION_TYPE=DECOMPOSITION_ALL_TYPE
      decomposition%NUMBER_OF_DOMAINS=0
      decomposition%NUMBER_OF_EDGES_CUT=0
      decomposition%numberOfElements=0
      NULLIFY(decomposition%topology)
      NULLIFY(decomposition%domain)
    ENDIF

    EXITS("Decomposition_Initialise")
    RETURN
999 CALL Decomposition_Finalise(decomposition,dummyErr,dummyError,*998)
998 ERRORSEXITS("Decomposition_Initialise",err,error)
    RETURN 1

  END SUBROUTINE Decomposition_Initialise

  !
  !================================================================================================================================
  !

  !!MERGE: ditto

  !>Gets the mesh component number which will be used for the decomposition of a mesh. \see OPENCMISS::Iron::cmfe_DecompositionMeshComponentGet
  SUBROUTINE DECOMPOSITION_MESH_COMPONENT_NUMBER_GET(DECOMPOSITION,MESH_COMPONENT_NUMBER,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION !<A pointer to the decomposition to get the mesh component for
    INTEGER(INTG), INTENT(OUT) :: MESH_COMPONENT_NUMBER !<On return, the mesh component number to get
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DECOMPOSITION_MESH_COMPONENT_NUMBER_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(DECOMPOSITION)) THEN
      IF(DECOMPOSITION%DECOMPOSITION_FINISHED) THEN
        IF(ASSOCIATED(DECOMPOSITION%MESH)) THEN
          MESH_COMPONENT_NUMBER=DECOMPOSITION%MESH_COMPONENT_NUMBER
        ELSE
          CALL FlagError("Decomposition mesh is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Decomposition has been finished.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Decomposition is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_MESH_COMPONENT_NUMBER_GET")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_MESH_COMPONENT_NUMBER_GET",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_MESH_COMPONENT_NUMBER_GET


  !
  !================================================================================================================================
  !

  !>Sets/changes the mesh component number which will be used for the decomposition of a mesh. \see OPENCMISS::Iron::cmfe_DecompositionMeshComponentSet
  SUBROUTINE DECOMPOSITION_MESH_COMPONENT_NUMBER_SET(DECOMPOSITION,MESH_COMPONENT_NUMBER,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION !<A pointer to the decomposition to set the mesh component for
    INTEGER(INTG), INTENT(IN) :: MESH_COMPONENT_NUMBER !<The mesh component number to set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("DECOMPOSITION_MESH_COMPONENT_NUMBER_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(DECOMPOSITION)) THEN
      IF(DECOMPOSITION%DECOMPOSITION_FINISHED) THEN
        CALL FlagError("Decomposition has been finished.",ERR,ERROR,*999)
      ELSE
        IF(ASSOCIATED(DECOMPOSITION%MESH)) THEN
          IF(MESH_COMPONENT_NUMBER>0.AND.MESH_COMPONENT_NUMBER<=DECOMPOSITION%numberOfComponents) THEN
            DECOMPOSITION%MESH_COMPONENT_NUMBER=MESH_COMPONENT_NUMBER
          ELSE
            LOCAL_ERROR="The specified mesh component number of "//TRIM(NUMBER_TO_VSTRING(MESH_COMPONENT_NUMBER,"*",ERR,ERROR))// &
              & "is invalid. The component number must be between 1 and "// &
              & TRIM(NUMBER_TO_VSTRING(DECOMPOSITION%numberOfComponents,"*",ERR,ERROR))//"."
            CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Decomposition mesh is not associated.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Decomposition is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_MESH_COMPONENT_NUMBER_SET")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_MESH_COMPONENT_NUMBER_SET",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_MESH_COMPONENT_NUMBER_SET

  !
  !================================================================================================================================
  !

  !!MERGE: ditto

  !>Gets the number of domains for a decomposition. \see OPENCMISS::Iron::cmfe_DecompositionNumberOfDomainsGet
  SUBROUTINE DECOMPOSITION_NUMBER_OF_DOMAINS_GET(DECOMPOSITION,NUMBER_OF_DOMAINS,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION !<A pointer to the decomposition to get the number of domains for.
    INTEGER(INTG), INTENT(OUT) :: NUMBER_OF_DOMAINS !<On return, the number of domains to get.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DECOMPOSITION_NUMBER_OF_DOMAINS_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(DECOMPOSITION)) THEN
      IF(DECOMPOSITION%DECOMPOSITION_FINISHED) THEN
        CALL FlagError("Decomposition has been finished.",ERR,ERROR,*999)
      ELSE
        NUMBER_OF_DOMAINS=DECOMPOSITION%NUMBER_OF_DOMAINS
      ENDIF
    ELSE
      CALL FlagError("Decomposition is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_NUMBER_OF_DOMAINS_GET")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_NUMBER_OF_DOMAINS_GET",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_NUMBER_OF_DOMAINS_GET


  !
  !================================================================================================================================
  !

  !>Sets/changes the number of domains for a decomposition. \see OPENCMISS::Iron::cmfe_DecompositionNumberOfDomainsSet
  SUBROUTINE DECOMPOSITION_NUMBER_OF_DOMAINS_SET(DECOMPOSITION,NUMBER_OF_DOMAINS,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION !<A pointer to the decomposition to set the number of domains for.
    INTEGER(INTG), INTENT(IN) :: NUMBER_OF_DOMAINS !<The number of domains to set.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: numberOfComputationalNodes
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("DECOMPOSITION_NUMBER_OF_DOMAINS_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(DECOMPOSITION)) THEN
      IF(DECOMPOSITION%DECOMPOSITION_FINISHED) THEN
        CALL FlagError("Decomposition has been finished.",ERR,ERROR,*999)
      ELSE
        SELECT CASE(DECOMPOSITION%DECOMPOSITION_TYPE)
        CASE(DECOMPOSITION_ALL_TYPE)
          IF(NUMBER_OF_DOMAINS==1) THEN
            DECOMPOSITION%NUMBER_OF_DOMAINS=1
          ELSE
            CALL FlagError("Can only have one domain for all decomposition type.",ERR,ERROR,*999)
          ENDIF
        CASE(DECOMPOSITION_CALCULATED_TYPE,DECOMPOSITION_USER_DEFINED_TYPE)
          IF(NUMBER_OF_DOMAINS>=1) THEN
            !wolfye???<=?
            IF(NUMBER_OF_DOMAINS<=DECOMPOSITION%numberOfElements) THEN
              !Get the number of computational nodes
              numberOfComputationalNodes=ComputationalEnvironment_NumberOfNodesGet(ERR,ERROR)
              IF(ERR/=0) GOTO 999
              !!TODO: relax this later
              !IF(NUMBER_OF_DOMAINS==numberOfComputationalNodes) THEN
                DECOMPOSITION%NUMBER_OF_DOMAINS=NUMBER_OF_DOMAINS
              !ELSE
              !  LOCAL_ERROR="The number of domains ("//TRIM(NUMBER_TO_VSTRING(NUMBER_OF_DOMAINSS,"*",ERR,ERROR))// &
              !    & ") is not equal to the number of computational nodes ("// &
              !    & TRIM(NUMBER_TO_VSTRING(numberOfComputationalNodes,"*",ERR,ERROR))//")"
              !  CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
              !ENDIF
            ELSE
              LOCAL_ERROR="The number of domains ("//TRIM(NUMBER_TO_VSTRING(NUMBER_OF_DOMAINS,"*",ERR,ERROR))// &
                & ") must be <= the number of global elements ("// &
                & TRIM(NUMBER_TO_VSTRING(DECOMPOSITION%numberOfElements,"*",ERR,ERROR))//") in the mesh."
              CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
            ENDIF
          ELSE
             CALL FlagError("Number of domains must be >= 1.",ERR,ERROR,*999)
           ENDIF
         CASE DEFAULT
          LOCAL_ERROR="Decomposition type "//TRIM(NUMBER_TO_VSTRING(DECOMPOSITION%DECOMPOSITION_TYPE,"*",ERR,ERROR))// &
            & " is not valid."
          CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
        END SELECT
      ENDIF
    ELSE
      CALL FlagError("Decomposition is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_NUMBER_OF_DOMAINS_SET")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_NUMBER_OF_DOMAINS_SET",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_NUMBER_OF_DOMAINS_SET

  !
  !================================================================================================================================
  !

  !>Calculates the topology for a decomposition.
  SUBROUTINE DECOMPOSITION_TOPOLOGY_CALCULATE(DECOMPOSITION,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION !<A pointer to the decomposition to finish creating.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: meshComponentNumber

    ENTERS("DECOMPOSITION_TOPOLOGY_CALCULATE",ERR,ERROR,*999)

    IF(ASSOCIATED(DECOMPOSITION%TOPOLOGY)) THEN
      !Calculate the elements topology
      CALL DECOMPOSITION_TOPOLOGY_ELEMENTS_CALCULATE(DECOMPOSITION%TOPOLOGY,ERR,ERROR,*999)
      !Calculate the line topology
      IF(DECOMPOSITION%CALCULATE_LINES)THEN
        CALL DECOMPOSITION_TOPOLOGY_LINES_CALCULATE(DECOMPOSITION%TOPOLOGY,ERR,ERROR,*999)
      ENDIF
      !Calculate the face topology
      IF(DECOMPOSITION%CALCULATE_FACES) THEN
        CALL DECOMPOSITION_TOPOLOGY_FACES_CALCULATE(DECOMPOSITION%TOPOLOGY,ERR,ERROR,*999)
      ENDIF
      meshComponentNumber=DECOMPOSITION%MESH_COMPONENT_NUMBER
      IF(ALLOCATED(DECOMPOSITION%MESH%TOPOLOGY(meshComponentNumber)%PTR%dataPoints%dataPoints)) THEN
          CALL DecompositionTopology_DataPointsCalculate(DECOMPOSITION%TOPOLOGY,ERR,ERROR,*999)
        ENDIF
    ELSE
      CALL FlagError("Topology is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_TOPOLOGY_CALCULATE")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_TOPOLOGY_CALCULATE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_TOPOLOGY_CALCULATE


  !
  !================================================================================================================================
  !

  !>Calculates the decomposition element topology.
  SUBROUTINE DecompositionTopology_DataPointsCalculate(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the decomposition topology to calculate the elements for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: localElement,globalElement,dataPointIdx,localData,meshComponentNumber
    INTEGER(INTG) :: INSERT_STATUS,MPI_IERROR,NUMBER_OF_COMPUTATIONAL_NODES,myComputationalNodeNumber,NUMBER_OF_GHOST_DATA, &
      & NUMBER_OF_LOCAL_DATA
    TYPE(DECOMPOSITION_TYPE), POINTER :: decomposition
    TYPE(DECOMPOSITION_ELEMENTS_TYPE), POINTER :: decompositionElements
    TYPE(DecompositionDataPointsType), POINTER :: decompositionData
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: elementsMapping
    TYPE(MeshDataPointsType), POINTER :: meshData

    ENTERS("DecompositionTopology_DataPointsCalculate",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      decompositionData=>TOPOLOGY%dataPoints
      IF(ASSOCIATED(decompositionData)) THEN
        decomposition=>decompositionData%DECOMPOSITION
        IF(ASSOCIATED(decomposition)) THEN
         decompositionElements=>TOPOLOGY%ELEMENTS
         IF(ASSOCIATED(decompositionElements)) THEN
           elementsMapping=>decomposition%DOMAIN(decomposition%MESH_COMPONENT_NUMBER)%PTR%MAPPINGS%ELEMENTS
           IF(ASSOCIATED(elementsMapping)) THEN
              meshComponentNumber=decomposition%MESH_COMPONENT_NUMBER
              meshData=>decomposition%MESH%TOPOLOGY(meshComponentNumber)%PTR%dataPoints
              IF(ASSOCIATED(meshData)) THEN
                NUMBER_OF_COMPUTATIONAL_NODES=ComputationalEnvironment_NumberOfNodesGet(ERR,ERROR)
                IF(ERR/=0) GOTO 999
                myComputationalNodeNumber=ComputationalEnvironment_NodeNumberGet(ERR,ERROR)
                IF(ERR/=0) GOTO 999
                ALLOCATE(decompositionData%numberOfDomainLocal(0:NUMBER_OF_COMPUTATIONAL_NODES-1),STAT=ERR)
                ALLOCATE(decompositionData%numberOfDomainGhost(0:NUMBER_OF_COMPUTATIONAL_NODES-1),STAT=ERR)
                ALLOCATE(decompositionData%numberOfElementDataPoints(decompositionElements%NUMBER_OF_GLOBAL_ELEMENTS),STAT=ERR)
                ALLOCATE(decompositionData%elementDataPoint(decompositionElements%TOTAL_NUMBER_OF_ELEMENTS),STAT=ERR)
                IF(ERR/=0) CALL FlagError("Could not allocate decomposition element data points.",ERR,ERROR,*999)
                CALL TREE_CREATE_START(decompositionData%dataPointsTree,ERR,ERROR,*999)
                CALL TREE_INSERT_TYPE_SET(decompositionData%dataPointsTree,TREE_NO_DUPLICATES_ALLOWED,ERR,ERROR,*999)
                CALL TREE_CREATE_FINISH(decompositionData%dataPointsTree,ERR,ERROR,*999)
                decompositionData%numberOfGlobalDataPoints=meshData%totalNumberOfProjectedData
                DO globalElement=1,decompositionElements%NUMBER_OF_GLOBAL_ELEMENTS
                  decompositionData%numberOfElementDataPoints(globalElement)= &
                    & meshData%elementDataPoint(globalElement)%numberOfProjectedData
                ENDDO !globalElement
                localData=0;
                DO localElement=1,decompositionElements%TOTAL_NUMBER_OF_ELEMENTS
                  globalElement=decompositionElements%ELEMENTS(localElement)%GLOBAL_NUMBER
                  decompositionData%elementDataPoint(localElement)%numberOfProjectedData= &
                    & meshData%elementDataPoint(globalElement)%numberOfProjectedData
                  decompositionData%elementDataPoint(localElement)%globalElementNumber=globalElement
                  IF(localElement<elementsMapping%GHOST_START) THEN
                    decompositionData%numberOfDataPoints=decompositionData%numberOfDataPoints+ &
                      & decompositionData%elementDataPoint(localElement)%numberOfProjectedData
                  ENDIF
                  decompositionData%totalNumberOfDataPoints=decompositionData%totalNumberOfDataPoints+ &
                    & decompositionData%elementDataPoint(localElement)%numberOfProjectedData
                  ALLOCATE(decompositionData%elementDataPoint(localElement)%dataIndices(decompositionData% &
                    & elementDataPoint(localElement)%numberOfProjectedData),STAT=ERR)
                  DO dataPointIdx=1,decompositionData%elementDataPoint(localElement)%numberOfProjectedData
                    decompositionData%elementDataPoint(localElement)%dataIndices(dataPointIdx)%userNumber= &
                      & meshData%elementDataPoint(globalElement)%dataIndices(dataPointIdx)%userNumber
                    decompositionData%elementDataPoint(localElement)%dataIndices(dataPointIdx)%globalNumber= &
                      & meshData%elementDataPoint(globalElement)%dataIndices(dataPointIdx)%globalNumber
                    localData=localData+1
                    decompositionData%elementDataPoint(localElement)%dataIndices(dataPointIdx)%localNumber=localData
                    CALL TREE_ITEM_INSERT(decompositionData%dataPointsTree,decompositionData% &
                      & elementDataPoint(localElement)%dataIndices(dataPointIdx)%userNumber,localData, &
                      & INSERT_STATUS,ERR,ERROR,*999)
                  ENDDO !dataPointIdx
                ENDDO !localElement
                !Calculate number of ghost data points on the current computational domain
                NUMBER_OF_LOCAL_DATA=decompositionData%numberOfDataPoints
                NUMBER_OF_GHOST_DATA=decompositionData%totalNumberOfDataPoints-decompositionData%numberOfDataPoints
                !Gather number of local data points on all computational nodes
                CALL MPI_ALLGATHER(NUMBER_OF_LOCAL_DATA,1,MPI_INTEGER,decompositionData% &
                  & numberOfDomainLocal,1,MPI_INTEGER,computationalEnvironment%mpiCommunicator,MPI_IERROR)
                CALL MPI_ERROR_CHECK("MPI_ALLGATHER",MPI_IERROR,ERR,ERROR,*999)
                !Gather number of ghost data points on all computational nodes
                CALL MPI_ALLGATHER(NUMBER_OF_GHOST_DATA,1,MPI_INTEGER,decompositionData% &
                  & numberOfDomainGhost,1,MPI_INTEGER,computationalEnvironment%mpiCommunicator,MPI_IERROR)
                CALL MPI_ERROR_CHECK("MPI_ALLGATHER",MPI_IERROR,ERR,ERROR,*999)
              ELSE
                CALL FlagError("Mesh data points topology is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FlagError("Element mapping  is not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Decomposition elements topology is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Decomposition is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Decomposition data points topology is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DecompositionTopology_DataPointsCalculate")
    RETURN
999 ERRORSEXITS("DecompositionTopology_DataPointsCalculate",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DecompositionTopology_DataPointsCalculate

  !
  !================================================================================================================================
  !

  !>Calculates the decomposition element topology for a data projection (for data projections on fields).
  SUBROUTINE DecompositionTopology_DataProjectionCalculate(decompositionTopology,err,error,*)

    !Argument variables
    TYPE(DECOMPOSITION_TOPOLOGY_TYPE), POINTER :: decompositionTopology !<A pointer to the decomposition topology to calculate the elements for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string

    ENTERS("DecompositionTopology_DataProjectionCalculate",err,error,*999)

    IF(ASSOCIATED(decompositionTopology)) THEN
      CALL DecompositionTopology_DataPointsInitialise(decompositionTopology,err,error,*999)
      CALL DecompositionTopology_DataPointsCalculate(decompositionTopology,err,error,*999)
    ELSE
      CALL FlagError("Decomposition topology is not associated.",err,error,*999)
    ENDIF

    EXITS("DecompositionTopology_DataProjectionCalculate")
    RETURN
999 ERRORS("DecompositionTopology_DataProjectionCalculate",err,error)
    EXITS("DecompositionTopology_DataProjectionCalculate")
    RETURN 1

  END SUBROUTINE DecompositionTopology_DataProjectionCalculate

  !
  !================================================================================================================================
  !

  !>Gets the local data point number for data points projected on an element
  SUBROUTINE DecompositionTopology_ElementDataPointLocalNumberGet(decompositionTopology,elementNumber,dataPointIndex, &
       & dataPointLocalNumber,err,error,*)

    !Argument variables
    TYPE(DECOMPOSITION_TOPOLOGY_TYPE), POINTER :: decompositionTopology !<A pointer to the decomposition topology to calculate the elements for
    INTEGER(INTG), INTENT(IN) :: elementNumber !<The element number to get the data point for
    INTEGER(INTG), INTENT(IN) :: dataPointIndex !<The data point index to get the number for
    INTEGER(INTG), INTENT(OUT) :: dataPointLocalNumber !<The data point local number to return
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local variables
    TYPE(DecompositionDataPointsType), POINTER :: decompositionData
    INTEGER(INTG) :: numberOfDataPoints
    TYPE(VARYING_STRING) :: localError

    ENTERS("DecompositionTopology_ElementDataPointLocalNumberGet",err,error,*999)

    IF(ASSOCIATED(decompositionTopology)) THEN
      decompositionData=>decompositionTopology%dataPoints
      IF(ASSOCIATED(decompositionData)) THEN
        numberOfDataPoints = decompositionData%elementDataPoint(elementNumber)%numberOfProjectedData
        IF(dataPointIndex > 0 .AND. dataPointIndex <= numberOfDataPoints) THEN
          dataPointLocalNumber = decompositionData%elementDataPoint(elementNumber)%dataIndices(dataPointIndex)%localNumber
        ELSE
          localError="Element data point index "//TRIM(NUMBER_TO_VSTRING(dataPointIndex,"*",ERR,ERROR))// &
           & " out of range for element "//TRIM(NUMBER_TO_VSTRING(elementNumber,"*",ERR,ERROR))//"."
          CALL FlagError(localError,err,error,*999)
        ENDIF
      ELSE
        CALL FlagError("Decomposition topology data points are not associated.",err,error,*999)
      ENDIF
    ELSE
      CALL FlagError("Decomposition topology is not associated.",err,error,*999)
    ENDIF

    EXITS("DecompositionTopology_ElementDataPointLocalNumberGet")
    RETURN
999 ERRORS("DecompositionTopology_ElementDataPointLocalNumberGet",err,error)
    EXITS("DecompositionTopology_ElementDataPointLocalNumberGet")
    RETURN 1
  END SUBROUTINE DecompositionTopology_ElementDataPointLocalNumberGet

  !
  !================================================================================================================================
  !

  !>Gets the user (global) data point number for data points projected on an element
  SUBROUTINE DecompositionTopology_ElementDataPointUserNumberGet(decompositionTopology,userElementNumber,dataPointIndex, &
       & dataPointUserNumber,err,error,*)

    !Argument variables
    TYPE(DECOMPOSITION_TOPOLOGY_TYPE), POINTER :: decompositionTopology !<A pointer to the decomposition topology to calculate the elements for
    INTEGER(INTG), INTENT(IN) :: userElementNumber !<The element number to get the data point for
    INTEGER(INTG), INTENT(IN) :: dataPointIndex !<The data point index to get the number for
    INTEGER(INTG), INTENT(OUT) :: dataPointUserNumber !<The data point user number to return
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local variables
    TYPE(DecompositionDataPointsType), POINTER :: decompositionData
    INTEGER(INTG) :: numberOfDataPoints,decompositionLocalElementNumber
    LOGICAL :: ghostElement,userElementExists
    TYPE(VARYING_STRING) :: localError

    ENTERS("DecompositionTopology_ElementDataPointUserNumberGet",err,error,*999)

    IF(ASSOCIATED(decompositionTopology)) THEN
      decompositionData=>decompositionTopology%dataPoints
      IF(ASSOCIATED(decompositionData)) THEN
        CALL DECOMPOSITION_TOPOLOGY_ELEMENT_CHECK_EXISTS(decompositionTopology,userElementNumber, &
          & userElementExists,decompositionLocalElementNumber,ghostElement,err,error,*999)
        IF(userElementExists) THEN
          IF(ghostElement) THEN
            localError="Cannot update by data point for user element "// &
              & TRIM(NUMBER_TO_VSTRING(userElementNumber,"*",err,error))//" as it is a ghost element."
            CALL FlagError(localError,err,error,*999)
          ELSE
            numberOfDataPoints = decompositionData%elementDataPoint(decompositionLocalElementNumber)%numberOfProjectedData
            IF(dataPointIndex > 0 .AND. dataPointIndex <= numberOfDataPoints) THEN
              dataPointUserNumber = decompositionData%elementDataPoint(decompositionLocalElementNumber)% &
                & dataIndices(dataPointIndex)%userNumber
            ELSE
              localError="Element data point index "//TRIM(NUMBER_TO_VSTRING(dataPointIndex,"*",ERR,ERROR))// &
               & " out of range for element "//TRIM(NUMBER_TO_VSTRING(userElementNumber,"*",ERR,ERROR))//"."
              CALL FlagError(localError,err,error,*999)
            ENDIF
          ENDIF
        ELSE
          localError="The specified user element number of "// &
            & TRIM(NUMBER_TO_VSTRING(userElementNumber,"*",err,error))// &
            & " does not exist."
          CALL FlagError(localError,err,error,*999)
        ENDIF
      ELSE
        CALL FlagError("Decomposition topology data points are not associated.",err,error,*999)
      ENDIF
    ELSE
      CALL FlagError("Decomposition topology is not associated.",err,error,*999)
    ENDIF

    EXITS("DecompositionTopology_ElementDataPointUserNumberGet")
    RETURN
999 ERRORS("DecompositionTopology_ElementDataPointUserNumberGet",err,error)
    EXITS("DecompositionTopology_ElementDataPointUserNumberGet")
    RETURN 1

  END SUBROUTINE DecompositionTopology_ElementDataPointUserNumberGet

  !
  !================================================================================================================================
  !

  !>Gets the number of data points projected on an element
  SUBROUTINE DecompositionTopology_NumberOfElementDataPointsGet(decompositionTopology,userElementNumber, &
       & numberOfDataPoints,err,error,*)

    !Argument variables
    TYPE(DECOMPOSITION_TOPOLOGY_TYPE), POINTER :: decompositionTopology !<A pointer to the decomposition topology to calculate the elements for
    INTEGER(INTG), INTENT(IN) :: userElementNumber !<The element number to get the data point for
    INTEGER(INTG), INTENT(OUT) :: numberOfDataPoints !<The data point local number to return
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local variables
    TYPE(DecompositionDataPointsType), POINTER :: decompositionData
    INTEGER(INTG) :: decompositionLocalElementNumber
    LOGICAL :: ghostElement,userElementExists
    TYPE(VARYING_STRING) :: localError

    ENTERS("DecompositionTopology_NumberOfElementDataPointsGet",err,error,*999)

    IF(ASSOCIATED(decompositionTopology)) THEN
      decompositionData=>decompositionTopology%dataPoints
      IF(ASSOCIATED(decompositionData)) THEN
        CALL DECOMPOSITION_TOPOLOGY_ELEMENT_CHECK_EXISTS(decompositionTopology,userElementNumber, &
          & userElementExists,decompositionLocalElementNumber,ghostElement,err,error,*999)
        IF(userElementExists) THEN
          IF(ghostElement) THEN
            localError="Cannot update by data point for user element "// &
              & TRIM(NUMBER_TO_VSTRING(userElementNumber,"*",err,error))//" as it is a ghost element."
            CALL FlagError(localError,err,error,*999)
          ELSE
            numberOfDataPoints = decompositionData%elementDataPoint(decompositionLocalElementNumber)%numberOfProjectedData
          ENDIF
        ELSE
          localError="The specified user element number of "// &
            & TRIM(NUMBER_TO_VSTRING(userElementNumber,"*",err,error))// &
            & " does not exist."
          CALL FlagError(localError,err,error,*999)
        ENDIF
      ELSE
        CALL FlagError("Decomposition topology data points are not associated.",err,error,*999)
      ENDIF
    ELSE
      CALL FlagError("Decomposition topology is not associated.",err,error,*999)
    ENDIF

    EXITS("DecompositionTopology_NumberOfElementDataPointsGet")
    RETURN
999 ERRORS("DecompositionTopology_NumberOfElementDataPointsGet",err,error)
    EXITS("DecompositionTopology_NumberOfElementDataPointsGet")
    RETURN 1
  END SUBROUTINE DecompositionTopology_NumberOfElementDataPointsGet

  !
  !================================================================================================================================
  !

  !>Checks that a user element number exists in a decomposition.
  SUBROUTINE DecompositionTopology_DataPointCheckExists(decompositionTopology,userDataPointNumber,userDataPointExists, &
        & decompositionLocalDataPointNumber,ghostDataPoint,err,error,*)

    !Argument variables
    TYPE(DECOMPOSITION_TOPOLOGY_TYPE), POINTER :: decompositionTopology !<A pointer to the decomposition topology to check the data point exists on
    INTEGER(INTG), INTENT(IN) :: userDataPointNumber !<The user data point number to check if it exists
    LOGICAL, INTENT(OUT) :: userDataPointExists !<On exit, is .TRUE. if the data point user number exists in the decomposition topology, .FALSE. if not
    INTEGER(INTG), INTENT(OUT) :: decompositionLocalDataPointNumber !<On exit, if the data point exists the local number corresponding to the user data point number. If the data point does not exist then local number will be 0.
    LOGICAL, INTENT(OUT) :: ghostDataPoint !<On exit, is .TRUE. if the local data point (if it exists) is a ghost data point, .FALSE. if not.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    TYPE(DecompositionDataPointsType), POINTER :: decompositionData
    TYPE(TREE_NODE_TYPE), POINTER :: treeNode

    ENTERS("DecompositionTopology_DataPointCheckExists",ERR,error,*999)

    userDataPointExists=.FALSE.
    decompositionLocalDataPointNumber=0
    ghostDataPoint=.FALSE.
    IF(ASSOCIATED(decompositionTopology)) THEN
      decompositionData=>decompositionTopology%dataPoints
      IF(ASSOCIATED(decompositionData)) THEN
        NULLIFY(treeNode)
        CALL TREE_SEARCH(decompositionData%dataPointsTree,userDataPointNumber,treeNode,err,error,*999)
        IF(ASSOCIATED(treeNode)) THEN
          CALL TREE_NODE_VALUE_GET(decompositionData%dataPointsTree,treeNode,decompositionLocalDataPointNumber,err,error,*999)
          userDataPointExists=.TRUE.
          ghostDataPoint=decompositionLocalDataPointNumber>decompositionData%numberOfDataPoints
        ENDIF
      ELSE
        CALL FlagError("Decomposition data point topology is not associated.",err,error,*999)
      ENDIF
    ELSE
      CALL FlagError("Decomposition topology is not associated.",err,error,*999)
    ENDIF

    EXITS("DecompositionTopology_DataPointCheckExists")
    RETURN
999 ERRORS("DecompositionTopology_DataPointCheckExists",err,error)
    EXITS("DecompositionTopology_DataPointCheckExists")
    RETURN 1

  END SUBROUTINE DecompositionTopology_DataPointCheckExists

  !
  !================================================================================================================================
  !

  !>Checks that a user element number exists in a decomposition.
  SUBROUTINE DecompositionTopology_ElementCheckExists(decompositionTopology,userElementNumber,elementExists,localElementNumber, &
    & ghostElement,err,error,*)

    !Argument variables
    TYPE(DECOMPOSITION_TOPOLOGY_TYPE), POINTER :: decompositionTopology !<A pointer to the decomposition topology to check the element exists on
    INTEGER(INTG), INTENT(IN) :: userElementNumber !<The user element number to check if it exists
    LOGICAL, INTENT(OUT) :: elementExists!<On exit, is .TRUE. if the element user number exists in the decomposition topology, .FALSE. if not
    INTEGER(INTG), INTENT(OUT) :: localElementNumber !<On exit, if the element exists the local number corresponding to the user element number. If the element does not exist then local number will be 0.
    LOGICAL, INTENT(OUT) :: ghostElement !<On exit, is .TRUE. if the local element (if it exists) is a ghost element, .FALSE. if not.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    TYPE(DECOMPOSITION_ELEMENTS_TYPE), POINTER :: decompositionElements
    TYPE(TREE_NODE_TYPE), POINTER :: treeNode

    ENTERS("DecompositionTopology_ElementCheckExists",err,error,*999)

    elementExists=.FALSE.
    localElementNumber=0
    ghostElement=.FALSE.
    IF(.NOT.ASSOCIATED(decompositionTopology)) CALL FlagError("Decomposition topology is not associated.",err,error,*999)

    NULLIFY(decompositionElements)
    CALL DecompositionTopology_ElementsGet(decompositionTopology,decompositionElements,err,error,*999)
    NULLIFY(treeNode)
    CALL Tree_Search(decompositionElements%ELEMENTS_TREE,userElementNumber,treeNode,err,error,*999)
    IF(ASSOCIATED(treeNode)) THEN
      CALL Tree_NodeValueGet(decompositionElements%ELEMENTS_TREE,treeNode,localElementNumber,err,error,*999)
      elementExists=.TRUE.
      ghostElement=localElementNumber>decompositionElements%NUMBER_OF_ELEMENTS
    ENDIF

    EXITS("DecompositionTopology_ElementCheckExists")
    RETURN
999 ERRORSEXITS("DecompositionTopology_ElementCheckExists",err,error)
    RETURN 1

  END SUBROUTINE DecompositionTopology_ElementCheckExists

  !
  !================================================================================================================================
  !

!!TODO: Should this be decompositionElements???
  !>Gets a local element number that corresponds to a user element number from a decomposition. An error will be raised if the user element number does not exist.
  SUBROUTINE DecompositionTopology_ElementGet(decompositionTopology,userElementNumber,localElementNumber,ghostElement,err,error,*)

    !Argument variables
    TYPE(DECOMPOSITION_TOPOLOGY_TYPE), POINTER :: decompositionTopology !<A pointer to the decomposition topology to get the element on
    INTEGER(INTG), INTENT(IN) :: userElementNumber !<The user element number to get
    INTEGER(INTG), INTENT(OUT) :: localElementNumber !<On exit, the local number corresponding to the user element number.
    LOGICAL, INTENT(OUT) :: ghostElement !<On exit, is .TRUE. if the local element is a ghost element, .FALSE. if not.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    LOGICAL :: elementExists
    TYPE(DECOMPOSITION_TYPE), POINTER :: decomposition
    TYPE(VARYING_STRING) :: localError

    ENTERS("DecompositionTopology_ElementGet",err,error,*999)

    CALL DecompositionTopology_ElementCheckExists(decompositionTopology,userElementNumber,elementExists,localElementNumber, &
      & ghostElement,err,error,*999)
    IF(.NOT.elementExists) THEN
      decomposition=>decompositionTopology%decomposition
      IF(ASSOCIATED(decomposition)) THEN
        localError="The user element number "//TRIM(NumberToVString(userElementNumber,"*",err,error))// &
          & " does not exist in decomposition number "//TRIM(NumberToVString(decomposition%USER_NUMBER,"*",err,error))//"."
        CALL FlagError(localError,err,error,*999)
      ELSE
        localError="The user element number "//TRIM(NumberToVString(userElementNumber,"*",err,error))//" does not exist."
        CALL FlagError(localError,err,error,*999)
      ENDIF
    ENDIF

    EXITS("DecompositionTopology_ElementGet")
    RETURN
999 ERRORSEXITS("DecompositionTopology_ElementGet",err,error)
    RETURN 1

  END SUBROUTINE DecompositionTopology_ElementGet

  !
  !================================================================================================================================
  !

  !>Finalises the given decomposition topology element.
  SUBROUTINE DECOMPOSITION_TOPOLOGY_ELEMENT_FINALISE(ELEMENT,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_ELEMENT_TYPE) :: ELEMENT !<The decomposition element to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: nic !\todo add comment

    ENTERS("DECOMPOSITION_TOPOLOGY_ELEMENT_FINALISE",ERR,ERROR,*999)

    IF(ALLOCATED(ELEMENT%ADJACENT_ELEMENTS)) THEN
      DO nic=LBOUND(ELEMENT%ADJACENT_ELEMENTS,1),UBOUND(ELEMENT%ADJACENT_ELEMENTS,1)
        CALL DECOMPOSITION_ADJACENT_ELEMENT_FINALISE(ELEMENT%ADJACENT_ELEMENTS(nic),ERR,ERROR,*999)
      ENDDO !nic
      DEALLOCATE(ELEMENT%ADJACENT_ELEMENTS)
    ENDIF
    IF(ALLOCATED(ELEMENT%ELEMENT_LINES)) DEALLOCATE(ELEMENT%ELEMENT_LINES)
    IF(ALLOCATED(ELEMENT%ELEMENT_FACES)) DEALLOCATE(ELEMENT%ELEMENT_FACES)

    EXITS("DECOMPOSITION_TOPOLOGY_ELEMENT_FINALISE")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_TOPOLOGY_ELEMENT_FINALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_TOPOLOGY_ELEMENT_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the given decomposition topology element.
  SUBROUTINE DECOMPOSITION_TOPOLOGY_ELEMENT_INITIALISE(ELEMENT,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_ELEMENT_TYPE) :: ELEMENT !<The decomposition element to initialise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DECOMPOSITION_TOPOLOGY_ELEMENT_INITIALISE",ERR,ERROR,*999)

    ELEMENT%USER_NUMBER=0
    ELEMENT%LOCAL_NUMBER=0
    ELEMENT%GLOBAL_NUMBER=0
    ELEMENT%BOUNDARY_ELEMENT=.FALSE.

    EXITS("DECOMPOSITION_TOPOLOGY_ELEMENT_INITIALISE")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_TOPOLOGY_ELEMENT_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_TOPOLOGY_ELEMENT_INITIALISE

  !
  !================================================================================================================================
  !

  !>Calculates the element numbers adjacent to an element in a decomposition topology.
  SUBROUTINE DecompositionTopology_ElementAdjacentElementCalculate(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the decomposition topology to calculate the adjacent elements for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: j,ne,ne1,nep1,ni,nic,nn,nn1,nn2,nn3,np,np1,DUMMY_ERR,FACE_XI(2),FACE_XIC(3),NODE_POSITION_INDEX(4)
    INTEGER(INTG) :: xi_direction,direction_index,xi_dir_check,xi_dir_search,NUMBER_NODE_MATCHES
    INTEGER(INTG) :: candidate_idx,face_node_idx,node_idx,surrounding_el_idx,candidate_el,idx
    INTEGER(INTG) :: NUMBER_SURROUNDING,NUMBER_OF_NODES_XIC(4),numberSurroundingElements
    INTEGER(INTG), ALLOCATABLE :: NODE_MATCHES(:),ADJACENT_ELEMENTS(:), surroundingElements(:)
    LOGICAL :: XI_COLLAPSED,FACE_COLLAPSED(-3:3),SUBSET
    TYPE(LIST_TYPE), POINTER :: NODE_MATCH_LIST, surroundingElementsList
    TYPE(LIST_PTR_TYPE) :: ADJACENT_ELEMENTS_LIST(-4:4)
    TYPE(BASIS_TYPE), POINTER :: BASIS
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION
    TYPE(DECOMPOSITION_ELEMENTS_TYPE), POINTER :: DECOMPOSITION_ELEMENTS
    TYPE(DOMAIN_TYPE), POINTER :: DOMAIN
    TYPE(DOMAIN_ELEMENTS_TYPE), POINTER :: DOMAIN_ELEMENTS
    TYPE(DOMAIN_NODES_TYPE), POINTER :: DOMAIN_NODES
    TYPE(DOMAIN_TOPOLOGY_TYPE), POINTER :: DOMAIN_TOPOLOGY
    TYPE(VARYING_STRING) :: DUMMY_ERROR,LOCAL_ERROR

    NULLIFY(NODE_MATCH_LIST)
    DO nic=-4,4
      NULLIFY(ADJACENT_ELEMENTS_LIST(nic)%PTR)
    ENDDO !nic

    ENTERS("DecompositionTopology_ElementAdjacentElementCalculate",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      DECOMPOSITION=>TOPOLOGY%DECOMPOSITION
      IF(ASSOCIATED(DECOMPOSITION)) THEN
        DECOMPOSITION_ELEMENTS=>TOPOLOGY%ELEMENTS
        IF(ASSOCIATED(DECOMPOSITION_ELEMENTS)) THEN
          DOMAIN=>DECOMPOSITION%DOMAIN(DECOMPOSITION%MESH_COMPONENT_NUMBER)%PTR
          IF(ASSOCIATED(DOMAIN)) THEN
            DOMAIN_TOPOLOGY=>DOMAIN%TOPOLOGY
            IF(ASSOCIATED(DOMAIN_TOPOLOGY)) THEN
              DOMAIN_NODES=>DOMAIN_TOPOLOGY%NODES
              IF(ASSOCIATED(DOMAIN_NODES)) THEN
                DOMAIN_ELEMENTS=>DOMAIN_TOPOLOGY%ELEMENTS
                IF(ASSOCIATED(DOMAIN_ELEMENTS)) THEN
                  !Loop over the elements in the decomposition
                  DO ne=1,DECOMPOSITION_ELEMENTS%TOTAL_NUMBER_OF_ELEMENTS
                    BASIS=>DOMAIN_ELEMENTS%ELEMENTS(ne)%BASIS
                    !Create a list for every xi direction (plus and minus)
                    DO nic=-BASIS%NUMBER_OF_XI_COORDINATES,BASIS%NUMBER_OF_XI_COORDINATES
                      NULLIFY(ADJACENT_ELEMENTS_LIST(nic)%PTR)
                      CALL LIST_CREATE_START(ADJACENT_ELEMENTS_LIST(nic)%PTR,ERR,ERROR,*999)
                      CALL LIST_DATA_TYPE_SET(ADJACENT_ELEMENTS_LIST(nic)%PTR,LIST_INTG_TYPE,ERR,ERROR,*999)
                      CALL LIST_INITIAL_SIZE_SET(ADJACENT_ELEMENTS_LIST(nic)%PTR,5,ERR,ERROR,*999)
                      CALL LIST_CREATE_FINISH(ADJACENT_ELEMENTS_LIST(nic)%PTR,ERR,ERROR,*999)
                    ENDDO !nic
                    NUMBER_OF_NODES_XIC=1
                    NUMBER_OF_NODES_XIC(1:BASIS%NUMBER_OF_XI_COORDINATES)= &
                      & BASIS%NUMBER_OF_NODES_XIC(1:BASIS%NUMBER_OF_XI_COORDINATES)
                    !Place the current element in the surrounding list
                    CALL LIST_ITEM_ADD(ADJACENT_ELEMENTS_LIST(0)%PTR,DECOMPOSITION_ELEMENTS%ELEMENTS(ne)%LOCAL_NUMBER, &
                      & ERR,ERROR,*999)
                    SELECT CASE(BASIS%TYPE)
                    CASE(BASIS_LAGRANGE_HERMITE_TP_TYPE)
!!TODO: Calculate this and set it as part of the basis type
                      !Determine the collapsed "faces" if any
                      NODE_POSITION_INDEX=1
                      !Loop over the face normals of the element
                      DO ni=1,BASIS%NUMBER_OF_XI
                        !Determine the face xi directions that lie in this xi direction
                        FACE_XI(1)=OTHER_XI_DIRECTIONS3(ni,2,1)
                        FACE_XI(2)=OTHER_XI_DIRECTIONS3(ni,3,1)
                        !Reset the node_position_index in this xi direction
                        NODE_POSITION_INDEX(ni)=1
                        !Loop over the two faces with this normal
                        DO direction_index=-1,1,2
                          xi_direction=direction_index*ni
                          FACE_COLLAPSED(xi_direction)=.FALSE.
                          DO j=1,2
                            xi_dir_check=FACE_XI(j)
                            IF(xi_dir_check<=BASIS%NUMBER_OF_XI) THEN
                              xi_dir_search=FACE_XI(3-j)
                              NODE_POSITION_INDEX(xi_dir_search)=1
                              XI_COLLAPSED=.TRUE.
                              DO WHILE(NODE_POSITION_INDEX(xi_dir_search)<=NUMBER_OF_NODES_XIC(xi_dir_search).AND.XI_COLLAPSED)
                                !Get the first local node along the xi check direction
                                NODE_POSITION_INDEX(xi_dir_check)=1
                                nn1=BASIS%NODE_POSITION_INDEX_INV(NODE_POSITION_INDEX(1),NODE_POSITION_INDEX(2), &
                                  & NODE_POSITION_INDEX(3),1)
                                !Get the second local node along the xi check direction
                                NODE_POSITION_INDEX(xi_dir_check)=2
                                nn2=BASIS%NODE_POSITION_INDEX_INV(NODE_POSITION_INDEX(1),NODE_POSITION_INDEX(2), &
                                  & NODE_POSITION_INDEX(3),1)
                                IF(nn1/=0.AND.nn2/=0) THEN
                                  IF(DOMAIN_ELEMENTS%ELEMENTS(ne)%ELEMENT_NODES(nn1)/= &
                                    & DOMAIN_ELEMENTS%ELEMENTS(ne)%ELEMENT_NODES(nn2)) XI_COLLAPSED=.FALSE.
                                ENDIF
                                NODE_POSITION_INDEX(xi_dir_search)=NODE_POSITION_INDEX(xi_dir_search)+1
                              ENDDO !xi_dir_search
                              IF(XI_COLLAPSED) FACE_COLLAPSED(xi_direction)=.TRUE.
                            ENDIF
                          ENDDO !j
                          NODE_POSITION_INDEX(ni)=NUMBER_OF_NODES_XIC(ni)
                        ENDDO !direction_index
                      ENDDO !ni
                      !Loop over the xi directions and calculate the surrounding elements
                      DO ni=1,BASIS%NUMBER_OF_XI
                        !Determine the xi directions that lie in this xi direction
                        FACE_XI(1)=OTHER_XI_DIRECTIONS3(ni,2,1)
                        FACE_XI(2)=OTHER_XI_DIRECTIONS3(ni,3,1)
                        !Loop over the two faces
                        DO direction_index=-1,1,2
                          xi_direction=direction_index*ni
                          !Find nodes in the element on the appropriate face/line/point
                          NULLIFY(NODE_MATCH_LIST)
                          CALL LIST_CREATE_START(NODE_MATCH_LIST,ERR,ERROR,*999)
                          CALL LIST_DATA_TYPE_SET(NODE_MATCH_LIST,LIST_INTG_TYPE,ERR,ERROR,*999)
                          CALL LIST_INITIAL_SIZE_SET(NODE_MATCH_LIST,16,ERR,ERROR,*999)
                          CALL LIST_CREATE_FINISH(NODE_MATCH_LIST,ERR,ERROR,*999)
                          IF(direction_index==-1) THEN
                            NODE_POSITION_INDEX(ni)=1
                          ELSE
                            NODE_POSITION_INDEX(ni)=NUMBER_OF_NODES_XIC(ni)
                          ENDIF
                          !If the face is collapsed then don't look in this xi direction. The exception is if the opposite face is
                          !also collapsed. This may indicate that we have a funny element in non-rc coordinates that goes around the
                          !central axis back to itself
                          IF(FACE_COLLAPSED(xi_direction).AND..NOT.FACE_COLLAPSED(-xi_direction)) THEN
                            !Do nothing - the match lists are already empty
                          ELSE
                            !Find the nodes to match and add them to the node match list
                            SELECT CASE(BASIS%NUMBER_OF_XI)
                            CASE(1)
                              nn=BASIS%NODE_POSITION_INDEX_INV(NODE_POSITION_INDEX(1),1,1,1)
                              IF(nn/=0) THEN
                                np=DOMAIN_ELEMENTS%ELEMENTS(ne)%ELEMENT_NODES(nn)
                                CALL LIST_ITEM_ADD(NODE_MATCH_LIST,np,ERR,ERROR,*999)
                              ENDIF
                            CASE(2)
                              DO nn1=1,NUMBER_OF_NODES_XIC(FACE_XI(1)),NUMBER_OF_NODES_XIC(FACE_XI(1))-1
                                NODE_POSITION_INDEX(FACE_XI(1))=nn1
                                nn=BASIS%NODE_POSITION_INDEX_INV(NODE_POSITION_INDEX(1),NODE_POSITION_INDEX(2),1,1)
                                IF(nn/=0) THEN
                                  np=DOMAIN_ELEMENTS%ELEMENTS(ne)%ELEMENT_NODES(nn)
                                  CALL LIST_ITEM_ADD(NODE_MATCH_LIST,np,ERR,ERROR,*999)
                                ENDIF
                              ENDDO !nn1
                            CASE(3)
                              DO nn1=1,NUMBER_OF_NODES_XIC(FACE_XI(1)),NUMBER_OF_NODES_XIC(FACE_XI(1))-1
                                NODE_POSITION_INDEX(FACE_XI(1))=nn1
                                DO nn2=1,NUMBER_OF_NODES_XIC(FACE_XI(2)),NUMBER_OF_NODES_XIC(FACE_XI(2))-1
                                  NODE_POSITION_INDEX(FACE_XI(2))=nn2
                                  nn=BASIS%NODE_POSITION_INDEX_INV(NODE_POSITION_INDEX(1),NODE_POSITION_INDEX(2), &
                                    & NODE_POSITION_INDEX(3),1)
                                  IF(nn/=0) THEN
                                    np=DOMAIN_ELEMENTS%ELEMENTS(ne)%ELEMENT_NODES(nn)
                                    CALL LIST_ITEM_ADD(NODE_MATCH_LIST,np,ERR,ERROR,*999)
                                  ENDIF
                                ENDDO !nn2
                              ENDDO !nn1
                            CASE DEFAULT
                              LOCAL_ERROR="The number of xi directions in the basis of "// &
                                & TRIM(NUMBER_TO_VSTRING(BASIS%NUMBER_OF_XI,"*",ERR,ERROR))//" is invalid."
                              CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                            END SELECT
                          ENDIF
                          CALL LIST_REMOVE_DUPLICATES(NODE_MATCH_LIST,ERR,ERROR,*999)
                          CALL LIST_DETACH_AND_DESTROY(NODE_MATCH_LIST,NUMBER_NODE_MATCHES,NODE_MATCHES,ERR,ERROR,*999)
                          NUMBER_SURROUNDING=0
                          IF(NUMBER_NODE_MATCHES>0) THEN
                            !NODE_MATCHES now contain the list of corner nodes in the current face with normal_xi of ni.
                            !Look at the surrounding elements of each of these nodes, if there is a repeated element that
                            !is not the current element ne, it's an adjacent element.
                            candidate_idx=0
                            NULLIFY(surroundingElementsList)
                            CALL LIST_CREATE_START(surroundingElementsList,ERR,ERROR,*999)
                            CALL LIST_DATA_TYPE_SET(surroundingElementsList,LIST_INTG_TYPE,ERR,ERROR,*999)
                            CALL LIST_INITIAL_SIZE_SET(surroundingElementsList,2,ERR,ERROR,*999)
                            CALL LIST_CREATE_FINISH(surroundingElementsList,ERR,ERROR,*999)
                            DO face_node_idx=1,NUMBER_NODE_MATCHES
                              !Dump all the surrounding elements into an array, see if any are repeated
                              node_idx=NODE_MATCHES(face_node_idx)
                              DO surrounding_el_idx=1,DOMAIN_NODES%NODES(node_idx)%NUMBER_OF_SURROUNDING_ELEMENTS
                                candidate_el=DOMAIN_NODES%NODES(node_idx)%SURROUNDING_ELEMENTS(surrounding_el_idx)
                                IF(candidate_el/=ne) THEN
                                  candidate_idx=candidate_idx+1
                                  CALL LIST_ITEM_ADD(surroundingElementsList,candidate_el,ERR,ERROR,*999)
                                ENDIF
                              ENDDO
                            ENDDO !face_node_idx
                            CALL LIST_DETACH_AND_DESTROY(surroundingElementsList,numberSurroundingElements,surroundingElements, &
                              & ERR,ERROR,*999)
                            DO idx=1,candidate_idx
                              ne1=surroundingElements(idx)
                              IF(COUNT(surroundingElements(1:numberSurroundingElements)==ne1)>=BASIS%NUMBER_OF_XI) THEN
                                !Found it, just exit
                                CALL LIST_ITEM_ADD(ADJACENT_ELEMENTS_LIST(xi_direction)%PTR,ne1,ERR,ERROR,*999)
                                NUMBER_SURROUNDING=NUMBER_SURROUNDING+1
                                EXIT
                              ENDIF
                            ENDDO
                          ENDIF
                          IF(ALLOCATED(NODE_MATCHES)) DEALLOCATE(NODE_MATCHES)
                          IF(ALLOCATED(surroundingElements)) DEALLOCATE(surroundingElements)
                        ENDDO !direction_index
                      ENDDO !ni
                    CASE(BASIS_SIMPLEX_TYPE)
                      !Loop over the xi coordinates and calculate the surrounding elements
                      DO nic=1,BASIS%NUMBER_OF_XI_COORDINATES
                        !Find the other coordinates of the face/line/point
                        FACE_XIC(1)=OTHER_XI_DIRECTIONS4(nic,1)
                        FACE_XIC(2)=OTHER_XI_DIRECTIONS4(nic,2)
                        FACE_XIC(3)=OTHER_XI_DIRECTIONS4(nic,3)
                        !Find nodes in the element on the appropriate face/line/point
                        NULLIFY(NODE_MATCH_LIST)
                        CALL LIST_CREATE_START(NODE_MATCH_LIST,ERR,ERROR,*999)
                        CALL LIST_DATA_TYPE_SET(NODE_MATCH_LIST,LIST_INTG_TYPE,ERR,ERROR,*999)
                        CALL LIST_INITIAL_SIZE_SET(NODE_MATCH_LIST,16,ERR,ERROR,*999)
                        CALL LIST_CREATE_FINISH(NODE_MATCH_LIST,ERR,ERROR,*999)
                        NODE_POSITION_INDEX(nic)=1 !Furtherest away from node with the nic'th coordinate
                        !Find the nodes to match and add them to the node match list
                        DO nn1=1,NUMBER_OF_NODES_XIC(FACE_XIC(1))
                          NODE_POSITION_INDEX(FACE_XIC(1))=nn1
                          DO nn2=1,NUMBER_OF_NODES_XIC(FACE_XIC(2))
                            NODE_POSITION_INDEX(FACE_XIC(2))=nn2
                            DO nn3=1,NUMBER_OF_NODES_XIC(FACE_XIC(3))
                              NODE_POSITION_INDEX(FACE_XIC(3))=nn3
                              nn=BASIS%NODE_POSITION_INDEX_INV(NODE_POSITION_INDEX(1),NODE_POSITION_INDEX(2), &
                                & NODE_POSITION_INDEX(3),NODE_POSITION_INDEX(4))
                              IF(nn/=0) THEN
                                np=DOMAIN_ELEMENTS%ELEMENTS(ne)%ELEMENT_NODES(nn)
                                CALL LIST_ITEM_ADD(NODE_MATCH_LIST,np,ERR,ERROR,*999)
                              ENDIF
                            ENDDO !nn3
                          ENDDO !nn2
                        ENDDO !nn1
                        CALL LIST_REMOVE_DUPLICATES(NODE_MATCH_LIST,ERR,ERROR,*999)
                        CALL LIST_DETACH_AND_DESTROY(NODE_MATCH_LIST,NUMBER_NODE_MATCHES,NODE_MATCHES,ERR,ERROR,*999)
                        IF(NUMBER_NODE_MATCHES>0) THEN
                          !Find list of elements surrounding those nodes
                          DO node_idx=1,NUMBER_NODE_MATCHES
                            np1=NODE_MATCHES(node_idx)
                            DO nep1=1,DOMAIN_NODES%NODES(np1)%NUMBER_OF_SURROUNDING_ELEMENTS
                              ne1=DOMAIN_NODES%NODES(np1)%SURROUNDING_ELEMENTS(nep1)
                              IF(ne1/=ne) THEN !Don't want the current element
                                ! grab the nodes list for current and this surrouding elements
                                ! current face : NODE_MATCHES
                                ! candidate elem : TOPOLOGY%ELEMENTS%ELEMENTS(ne1)%MESH_ELEMENT_NODES
                                ! if all of current face belongs to the candidate element, we will have found the neighbour
                                CALL LIST_SUBSET_OF(NODE_MATCHES(1:NUMBER_NODE_MATCHES),DOMAIN_ELEMENTS%ELEMENTS(ne1)% &
                                  & ELEMENT_NODES,SUBSET,ERR,ERROR,*999)
                                IF(SUBSET) THEN
                                  CALL LIST_ITEM_ADD(ADJACENT_ELEMENTS_LIST(nic)%PTR,ne1,ERR,ERROR,*999)
                                ENDIF
                              ENDIF
                            ENDDO !nep1
                          ENDDO !node_idx
                        ENDIF
                        IF(ALLOCATED(NODE_MATCHES)) DEALLOCATE(NODE_MATCHES)
                      ENDDO !nic
                    CASE(BASIS_SERENDIPITY_TYPE)
                      CALL FlagError("Not implemented.",ERR,ERROR,*999)
                    CASE(BASIS_AUXILLIARY_TYPE)
                      CALL FlagError("Not implemented.",ERR,ERROR,*999)
                    CASE(BASIS_B_SPLINE_TP_TYPE)
                      CALL FlagError("Not implemented.",ERR,ERROR,*999)
                    CASE(BASIS_FOURIER_LAGRANGE_HERMITE_TP_TYPE)
                      CALL FlagError("Not implemented.",ERR,ERROR,*999)
                    CASE(BASIS_EXTENDED_LAGRANGE_TP_TYPE)
                      CALL FlagError("Not implemented.",ERR,ERROR,*999)
                    CASE DEFAULT
                      LOCAL_ERROR="The basis type of "//TRIM(NUMBER_TO_VSTRING(BASIS%TYPE,"*",ERR,ERROR))// &
                        & " is invalid."
                      CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                    END SELECT
                    !Set the surrounding elements for this element
                    ALLOCATE(DECOMPOSITION_ELEMENTS%ELEMENTS(ne)%ADJACENT_ELEMENTS(-BASIS%NUMBER_OF_XI_COORDINATES: &
                      BASIS%NUMBER_OF_XI_COORDINATES),STAT=ERR)
                    IF(ERR/=0) CALL FlagError("Could not allocate adjacent elements.",ERR,ERROR,*999)
                    DO nic=-BASIS%NUMBER_OF_XI_COORDINATES,BASIS%NUMBER_OF_XI_COORDINATES
                      CALL DECOMPOSITION_ADJACENT_ELEMENT_INITIALISE(DECOMPOSITION_ELEMENTS%ELEMENTS(ne)%ADJACENT_ELEMENTS(nic), &
                        & ERR,ERROR,*999)
                      CALL LIST_DETACH_AND_DESTROY(ADJACENT_ELEMENTS_LIST(nic)%PTR,DECOMPOSITION_ELEMENTS%ELEMENTS(ne)% &
                        & ADJACENT_ELEMENTS(nic)%NUMBER_OF_ADJACENT_ELEMENTS,ADJACENT_ELEMENTS,ERR,ERROR,*999)
                      ALLOCATE(DECOMPOSITION_ELEMENTS%ELEMENTS(ne)%ADJACENT_ELEMENTS(nic)%ADJACENT_ELEMENTS( &
                        DECOMPOSITION_ELEMENTS%ELEMENTS(ne)%ADJACENT_ELEMENTS(nic)%NUMBER_OF_ADJACENT_ELEMENTS),STAT=ERR)
                      IF(ERR/=0) CALL FlagError("Could not allocate element adjacent elements.",ERR,ERROR,*999)
                      DECOMPOSITION_ELEMENTS%ELEMENTS(ne)%ADJACENT_ELEMENTS(nic)%ADJACENT_ELEMENTS(1: &
                        & DECOMPOSITION_ELEMENTS%ELEMENTS(ne)%ADJACENT_ELEMENTS(nic)%NUMBER_OF_ADJACENT_ELEMENTS)= &
                        ADJACENT_ELEMENTS(1:DECOMPOSITION_ELEMENTS%ELEMENTS(ne)%ADJACENT_ELEMENTS(nic)%NUMBER_OF_ADJACENT_ELEMENTS)
                      IF(ALLOCATED(ADJACENT_ELEMENTS)) DEALLOCATE(ADJACENT_ELEMENTS)
                    ENDDO !nic
                  ENDDO !ne
                ELSE
                  CALL FlagError("Domain topology elements is not associated.",ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FlagError("Domain topology nodes is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FlagError("Topology decomposition domain topology is not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Topology decomposition domain is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Topology elements is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Topology decomposition is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Topology is not allocated.",ERR,ERROR,*999)
    ENDIF

    IF(DIAGNOSTICS1) THEN
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"Total number of elements = ",DECOMPOSITION_ELEMENTS% &
        & TOTAL_NUMBER_OF_ELEMENTS,ERR,ERROR,*999)
      DO ne=1,DECOMPOSITION_ELEMENTS%TOTAL_NUMBER_OF_ELEMENTS
        BASIS=>DOMAIN_ELEMENTS%ELEMENTS(ne)%BASIS
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  Local element number : ",ne,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Number of xi coordinates = ",BASIS%NUMBER_OF_XI_COORDINATES, &
          & ERR,ERROR,*999)
        DO nic=-BASIS%NUMBER_OF_XI_COORDINATES,BASIS%NUMBER_OF_XI_COORDINATES
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Xi coordinate : ",nic,ERR,ERROR,*999)
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"        Number of adjacent elements = ", &
            & DECOMPOSITION_ELEMENTS%ELEMENTS(ne)%ADJACENT_ELEMENTS(nic)%NUMBER_OF_ADJACENT_ELEMENTS,ERR,ERROR,*999)
          IF(DECOMPOSITION_ELEMENTS%ELEMENTS(ne)%ADJACENT_ELEMENTS(nic)%NUMBER_OF_ADJACENT_ELEMENTS>0) THEN
            CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,DECOMPOSITION_ELEMENTS%ELEMENTS(ne)% &
              & ADJACENT_ELEMENTS(nic)%NUMBER_OF_ADJACENT_ELEMENTS,8,8,DECOMPOSITION_ELEMENTS%ELEMENTS(ne)%ADJACENT_ELEMENTS(nic)% &
              & ADJACENT_ELEMENTS,'("        Adjacent elements :",8(X,I6))','(30x,8(X,I6))',ERR,ERROR,*999)
          ENDIF
        ENDDO !nic
      ENDDO !ne
    ENDIF

    EXITS("DecompositionTopology_ElementAdjacentElementCalculate")
    RETURN
999 IF(ALLOCATED(NODE_MATCHES)) DEALLOCATE(NODE_MATCHES)
    IF(ALLOCATED(surroundingElements)) DEALLOCATE(surroundingElements)
    IF(ALLOCATED(ADJACENT_ELEMENTS)) DEALLOCATE(ADJACENT_ELEMENTS)
    IF(ASSOCIATED(NODE_MATCH_LIST)) CALL LIST_DESTROY(NODE_MATCH_LIST,DUMMY_ERR,DUMMY_ERROR,*998)
998 IF(ASSOCIATED(surroundingElementsList)) CALL LIST_DESTROY(surroundingElementsList,DUMMY_ERR,DUMMY_ERROR,*997)
997 DO nic=-4,4
      IF(ASSOCIATED(ADJACENT_ELEMENTS_LIST(nic)%PTR)) CALL LIST_DESTROY(ADJACENT_ELEMENTS_LIST(nic)%PTR,DUMMY_ERR,DUMMY_ERROR,*996)
    ENDDO !ni
996 ERRORS("DecompositionTopology_ElementAdjacentElementCalculate",ERR,ERROR)
    EXITS("DecompositionTopology_ElementAdjacentElementCalculate")
    RETURN 1

  END SUBROUTINE DecompositionTopology_ElementAdjacentElementCalculate

  !
  !================================================================================================================================
  !

  !>Calculates the decomposition element topology.
  SUBROUTINE DECOMPOSITION_TOPOLOGY_ELEMENTS_CALCULATE(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the decomposition topology to calculate the elements for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: global_element,INSERT_STATUS,local_element
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION
    TYPE(DECOMPOSITION_ELEMENTS_TYPE), POINTER :: DECOMPOSITION_ELEMENTS
    TYPE(DOMAIN_TYPE), POINTER :: DOMAIN
    TYPE(DOMAIN_ELEMENTS_TYPE), POINTER :: DOMAIN_ELEMENTS
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: DOMAIN_ELEMENTS_MAPPING
    TYPE(DOMAIN_MAPPINGS_TYPE), POINTER :: DOMAIN_MAPPINGS
    TYPE(DOMAIN_TOPOLOGY_TYPE), POINTER :: DOMAIN_TOPOLOGY
    TYPE(MESH_TYPE), POINTER :: MESH
    TYPE(MeshElementsType), POINTER :: MESH_ELEMENTS
    TYPE(MeshComponentTopologyType), POINTER :: MESH_TOPOLOGY

    ENTERS("DECOMPOSITION_TOPOLOGY_ELEMENTS_CALCULATE",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      DECOMPOSITION_ELEMENTS=>TOPOLOGY%ELEMENTS
      IF(ASSOCIATED(DECOMPOSITION_ELEMENTS)) THEN
        DECOMPOSITION=>TOPOLOGY%DECOMPOSITION
        IF(ASSOCIATED(DECOMPOSITION)) THEN
          DOMAIN=>DECOMPOSITION%DOMAIN(DECOMPOSITION%MESH_COMPONENT_NUMBER)%PTR
          IF(ASSOCIATED(DOMAIN)) THEN
            DOMAIN_TOPOLOGY=>DOMAIN%TOPOLOGY
            IF(ASSOCIATED(DOMAIN_TOPOLOGY)) THEN
              DOMAIN_ELEMENTS=>DOMAIN_TOPOLOGY%ELEMENTS
              IF(ASSOCIATED(DOMAIN_ELEMENTS)) THEN
                DOMAIN_MAPPINGS=>DOMAIN%MAPPINGS
                IF(ASSOCIATED(DOMAIN_MAPPINGS)) THEN
                  DOMAIN_ELEMENTS_MAPPING=>DOMAIN_MAPPINGS%ELEMENTS
                  IF(ASSOCIATED(DOMAIN_ELEMENTS_MAPPING)) THEN
                    MESH=>DECOMPOSITION%MESH
                    IF(ASSOCIATED(MESH)) THEN
                      MESH_TOPOLOGY=>MESH%TOPOLOGY(DECOMPOSITION%MESH_COMPONENT_NUMBER)%PTR
                      IF(ASSOCIATED(MESH_TOPOLOGY)) THEN
                        MESH_ELEMENTS=>MESH_TOPOLOGY%ELEMENTS
                        IF(ASSOCIATED(MESH_ELEMENTS)) THEN
                          !Allocate the element topology arrays
                          ALLOCATE(DECOMPOSITION_ELEMENTS%ELEMENTS(DOMAIN_ELEMENTS%TOTAL_NUMBER_OF_ELEMENTS),STAT=ERR)
                          IF(ERR/=0) CALL FlagError("Could not allocate decomposition elements elements.",ERR,ERROR,*999)
                          DECOMPOSITION_ELEMENTS%NUMBER_OF_ELEMENTS=DOMAIN_ELEMENTS%NUMBER_OF_ELEMENTS
                          DECOMPOSITION_ELEMENTS%TOTAL_NUMBER_OF_ELEMENTS=DOMAIN_ELEMENTS%TOTAL_NUMBER_OF_ELEMENTS
                          DECOMPOSITION_ELEMENTS%NUMBER_OF_GLOBAL_ELEMENTS=DOMAIN_ELEMENTS%NUMBER_OF_GLOBAL_ELEMENTS
                          CALL TREE_CREATE_START(DECOMPOSITION_ELEMENTS%ELEMENTS_TREE,ERR,ERROR,*999)
                          CALL TREE_INSERT_TYPE_SET(DECOMPOSITION_ELEMENTS%ELEMENTS_TREE,TREE_NO_DUPLICATES_ALLOWED,ERR,ERROR,*999)
                          CALL TREE_CREATE_FINISH(DECOMPOSITION_ELEMENTS%ELEMENTS_TREE,ERR,ERROR,*999)
                          DO local_element=1,DECOMPOSITION_ELEMENTS%TOTAL_NUMBER_OF_ELEMENTS
                            CALL DECOMPOSITION_TOPOLOGY_ELEMENT_INITIALISE(DECOMPOSITION_ELEMENTS%ELEMENTS(local_element), &
                              & ERR,ERROR,*999)
                            global_element=DOMAIN_ELEMENTS_MAPPING%LOCAL_TO_GLOBAL_MAP(local_element)
                            DECOMPOSITION_ELEMENTS%ELEMENTS(local_element)%USER_NUMBER=MESH_ELEMENTS%ELEMENTS(global_element)% &
                              & USER_NUMBER
                            DECOMPOSITION_ELEMENTS%ELEMENTS(local_element)%LOCAL_NUMBER=local_element
                            CALL TREE_ITEM_INSERT(DECOMPOSITION_ELEMENTS%ELEMENTS_TREE,DECOMPOSITION_ELEMENTS% &
                              & ELEMENTS(local_element)%USER_NUMBER,local_element,INSERT_STATUS,ERR,ERROR,*999)
                            DECOMPOSITION_ELEMENTS%ELEMENTS(local_element)%GLOBAL_NUMBER=global_element
                            DECOMPOSITION_ELEMENTS%ELEMENTS(local_element)%BOUNDARY_ELEMENT=MESH_ELEMENTS% &
                              & ELEMENTS(global_element)%BOUNDARY_ELEMENT
                          ENDDO !local_element
                          !Calculate the elements surrounding the elements in the decomposition topology
                          CALL DecompositionTopology_ElementAdjacentElementCalculate(TOPOLOGY,ERR,ERROR,*999)
                        ELSE
                          CALL FlagError("Mesh elements is not associated.",ERR,ERROR,*999)
                        ENDIF
                      ELSE
                        CALL FlagError("Mesh topology is not associated.",ERR,ERROR,*999)
                      ENDIF
                    ELSE
                      CALL FlagError("Decomposition mesh is not associated.",ERR,ERROR,*999)
                    ENDIF
                  ELSE
                    CALL FlagError("Domain mappings elements is not associated.",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FlagError("Domain mappings is not associated.",ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FlagError("Domain topology elements is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FlagError("Topology decomposition domain topology is not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Topology decomposition domain is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Topology decomposition is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Topology elements is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_TOPOLOGY_ELEMENTS_CALCULATE")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_TOPOLOGY_ELEMENTS_CALCULATE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_TOPOLOGY_ELEMENTS_CALCULATE

  !
  !================================================================================================================================
  !

  !>Finalises the elements in the given decomposition topology. \todo Pass in the decomposition elements pointer.
  SUBROUTINE DECOMPOSITION_TOPOLOGY_ELEMENTS_FINALISE(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the decomposition topology to finalise the elements for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: ne

    ENTERS("DECOMPOSITION_TOPOLOGY_ELEMENTS_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      IF(ASSOCIATED(TOPOLOGY%ELEMENTS)) THEN
        DO ne=1,TOPOLOGY%ELEMENTS%TOTAL_NUMBER_OF_ELEMENTS
          CALL DECOMPOSITION_TOPOLOGY_ELEMENT_FINALISE(TOPOLOGY%ELEMENTS%ELEMENTS(ne),ERR,ERROR,*999)
        ENDDO !ne
        IF(ASSOCIATED(TOPOLOGY%ELEMENTS%ELEMENTS)) DEALLOCATE(TOPOLOGY%ELEMENTS%ELEMENTS)
        IF(ASSOCIATED(TOPOLOGY%ELEMENTS%ELEMENTS_TREE)) CALL TREE_DESTROY(TOPOLOGY%ELEMENTS%ELEMENTS_TREE,ERR,ERROR,*999)
        DEALLOCATE(TOPOLOGY%ELEMENTS)
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_TOPOLOGY_ELEMENTS_FINALISE")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_TOPOLOGY_ELEMENTS_FINALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_TOPOLOGY_ELEMENTS_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the element data structures for a decomposition topology.
  SUBROUTINE DECOMPOSITION_TOPOLOGY_ELEMENTS_INITIALISE(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the decomposition topology to initialise the elements for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DECOMPOSITION_TOPOLOGY_ELEMENTS_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      IF(ASSOCIATED(TOPOLOGY%ELEMENTS)) THEN
        CALL FlagError("Decomposition already has topology elements associated.",ERR,ERROR,*999)
      ELSE
        ALLOCATE(TOPOLOGY%ELEMENTS,STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate topology elements.",ERR,ERROR,*999)
        TOPOLOGY%ELEMENTS%NUMBER_OF_ELEMENTS=0
        TOPOLOGY%ELEMENTS%TOTAL_NUMBER_OF_ELEMENTS=0
        TOPOLOGY%ELEMENTS%NUMBER_OF_GLOBAL_ELEMENTS=0
        TOPOLOGY%ELEMENTS%DECOMPOSITION=>TOPOLOGY%DECOMPOSITION
        NULLIFY(TOPOLOGY%ELEMENTS%ELEMENTS)
        NULLIFY(TOPOLOGY%ELEMENTS%ELEMENTS_TREE)
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_TOPOLOGY_ELEMENTS_INITIALISE")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_TOPOLOGY_ELEMENTS_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_TOPOLOGY_ELEMENTS_INITIALISE

  !
  !================================================================================================================================
  !

  !>Finalises the topology in the given decomposition. \todo Pass in a pointer to the decomposition topology
  SUBROUTINE DECOMPOSITION_TOPOLOGY_FINALISE(DECOMPOSITION,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION !<A pointer to the decomposition to finalise the topology for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DECOMPOSITION_TOPOLOGY_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(DECOMPOSITION)) THEN
      CALL DECOMPOSITION_TOPOLOGY_ELEMENTS_FINALISE(DECOMPOSITION%TOPOLOGY,ERR,ERROR,*999)
      IF(DECOMPOSITION%CALCULATE_LINES) THEN
        CALL DECOMPOSITION_TOPOLOGY_LINES_FINALISE(DECOMPOSITION%TOPOLOGY,ERR,ERROR,*999)
      ENDIF
      IF(DECOMPOSITION%CALCULATE_FACES) THEN
        CALL DECOMPOSITION_TOPOLOGY_FACES_FINALISE(DECOMPOSITION%TOPOLOGY,ERR,ERROR,*999)
      ENDIF
      DEALLOCATE(DECOMPOSITION%TOPOLOGY)
    ELSE
      CALL FlagError("Decomposition is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_TOPOLOGY_FINALISE")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_TOPOLOGY_FINALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DECOMPOSITION_TOPOLOGY_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the topology for a given decomposition.
  SUBROUTINE DECOMPOSITION_TOPOLOGY_INITIALISE(DECOMPOSITION,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION !<A pointer to the decomposition to initialise the topology for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: meshComponentNumber

    ENTERS("DECOMPOSITION_TOPOLOGY_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(DECOMPOSITION)) THEN
      IF(ASSOCIATED(DECOMPOSITION%TOPOLOGY)) THEN
        CALL FlagError("Decomposition already has topology associated.",ERR,ERROR,*999)
      ELSE
        !Allocate decomposition topology
        ALLOCATE(DECOMPOSITION%TOPOLOGY,STAT=ERR)
        IF(ERR/=0) CALL FlagError("Decomposition topology could not be allocated.",ERR,ERROR,*999)
        DECOMPOSITION%TOPOLOGY%DECOMPOSITION=>DECOMPOSITION
        NULLIFY(DECOMPOSITION%TOPOLOGY%ELEMENTS)
        NULLIFY(DECOMPOSITION%TOPOLOGY%LINES)
        NULLIFY(DECOMPOSITION%TOPOLOGY%FACES)
        NULLIFY(DECOMPOSITION%TOPOLOGY%dataPoints)
        !Initialise the topology components
        CALL DECOMPOSITION_TOPOLOGY_ELEMENTS_INITIALISE(DECOMPOSITION%TOPOLOGY,ERR,ERROR,*999)
        IF(DECOMPOSITION%CALCULATE_LINES) THEN !Default is currently true
          CALL DECOMPOSITION_TOPOLOGY_LINES_INITIALISE(DECOMPOSITION%TOPOLOGY,ERR,ERROR,*999)
        ENDIF
        IF(DECOMPOSITION%CALCULATE_FACES) THEN !Default is currently false
          CALL DECOMPOSITION_TOPOLOGY_FACES_INITIALISE(DECOMPOSITION%TOPOLOGY,ERR,ERROR,*999)
        ENDIF
        meshComponentNumber=DECOMPOSITION%MESH_COMPONENT_NUMBER
        IF(ALLOCATED(DECOMPOSITION%MESH%TOPOLOGY(meshComponentNumber)%PTR%dataPoints%dataPoints)) THEN
          CALL DecompositionTopology_DataPointsInitialise(DECOMPOSITION%TOPOLOGY,ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Decomposition is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_TOPOLOGY_INITIALISE")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_TOPOLOGY_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_TOPOLOGY_INITIALISE

  !
  !================================================================================================================================
  !

  !>Finalises a line in the given decomposition topology and deallocates all memory.
  SUBROUTINE DECOMPOSITION_TOPOLOGY_LINE_FINALISE(LINE,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_LINE_TYPE) :: LINE !<The decomposition line to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DECOMPOSITION_TOPOLOGY_LINE_FINALISE",ERR,ERROR,*999)

    LINE%NUMBER=0
    LINE%XI_DIRECTION=0
    LINE%NUMBER_OF_SURROUNDING_ELEMENTS=0
    IF(ALLOCATED(LINE%SURROUNDING_ELEMENTS)) DEALLOCATE(LINE%SURROUNDING_ELEMENTS)
    IF(ALLOCATED(LINE%ELEMENT_LINES)) DEALLOCATE(LINE%ELEMENT_LINES)
    LINE%ADJACENT_LINES=0

    EXITS("DECOMPOSITION_TOPOLOGY_LINE_FINALISE")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_TOPOLOGY_LINE_FINALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_TOPOLOGY_LINE_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the line data structure for a decomposition topology line.
  SUBROUTINE DECOMPOSITION_TOPOLOGY_LINE_INITIALISE(LINE,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_LINE_TYPE) :: LINE !<The decomposition line to initialise.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DECOMPOSITION_TOPOLOGY_LINE_INITIALISE",ERR,ERROR,*999)

    LINE%NUMBER=0
    LINE%XI_DIRECTION=0
    LINE%NUMBER_OF_SURROUNDING_ELEMENTS=0
    LINE%ADJACENT_LINES=0
    LINE%BOUNDARY_LINE=.FALSE.

    EXITS("DECOMPOSITION_TOPOLOGY_LINE_INITIALISE")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_TOPOLOGY_LINE_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_TOPOLOGY_LINE_INITIALISE

  !
  !================================================================================================================================
  !

  !>Calculates the lines in the given decomposition topology.
  SUBROUTINE DECOMPOSITION_TOPOLOGY_LINES_CALCULATE(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the decomposition topology to calculate the lines for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: component_idx,element_idx,surroundingElementLocalNo,basis_local_line_idx, &
      & surrounding_element_basis_local_line_idx,element_local_node_idx,basis_local_line_node_idx,derivative_idx,version_idx, &
      & local_line_idx,surrounding_element_local_line_idx,node_idx,local_node_idx,elem_idx,line_end_node_idx,basis_node_idx, &
      & NODES_IN_LINE(4),LINE_NUMBER,COUNT, xicIdx,elementLocalNo, &
      & elementGlobalNo, componentIdx, startNic, lineBasisLocalNo, lineGlobalNo, lineGlobalNo2, lineIdx, lineLocalNo
    INTEGER(INTG), ALLOCATABLE :: NODES_NUMBER_OF_LINES(:)
    INTEGER(INTG), POINTER :: TEMP_LINES(:,:),NEW_TEMP_LINES(:,:)
    LOGICAL :: FOUND
    TYPE(BASIS_TYPE), POINTER :: BASIS,BASIS2
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION
    TYPE(DECOMPOSITION_ELEMENT_TYPE), POINTER :: DECOMPOSITION_ELEMENT
    TYPE(DECOMPOSITION_ELEMENTS_TYPE), POINTER :: DECOMPOSITION_ELEMENTS
    TYPE(DECOMPOSITION_LINE_TYPE), POINTER :: DECOMPOSITION_LINE,DECOMPOSITION_LINE2
    TYPE(DECOMPOSITION_LINES_TYPE), POINTER :: DECOMPOSITION_LINES
    TYPE(DOMAIN_TYPE), POINTER :: DOMAIN
    TYPE(DOMAIN_ELEMENT_TYPE), POINTER :: DOMAIN_ELEMENT
    TYPE(DOMAIN_ELEMENTS_TYPE), POINTER :: DOMAIN_ELEMENTS
    TYPE(DOMAIN_LINE_TYPE), POINTER :: DOMAIN_LINE,DOMAIN_LINE2
    TYPE(DOMAIN_LINES_TYPE), POINTER :: DOMAIN_LINES
    TYPE(DOMAIN_NODE_TYPE), POINTER :: DOMAIN_NODE
    TYPE(DOMAIN_NODES_TYPE), POINTER :: DOMAIN_NODES
    TYPE(DOMAIN_TOPOLOGY_TYPE), POINTER :: DOMAIN_TOPOLOGY
    TYPE(DOMAIN_MAPPINGS_TYPE), POINTER :: DOMAIN_MAPPINGS
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: ELEMENTS_MAPPING, LINES_MAPPING
    TYPE(MESH_TYPE), POINTER :: MESH
    TYPE(MeshComponentTopologyType), POINTER :: MESH_TOPOLOGY

    NULLIFY(TEMP_LINES)
    NULLIFY(NEW_TEMP_LINES)

    ENTERS("DECOMPOSITION_TOPOLOGY_LINES_CALCULATE",ERR,ERROR,*999)

    IF(.NOT.ASSOCIATED(TOPOLOGY)) CALL FlagError("Topology is not associated.",ERR,ERROR,*999)
    DECOMPOSITION_LINES=>TOPOLOGY%LINES
    IF(.NOT.ASSOCIATED(DECOMPOSITION_LINES)) CALL FlagError("decomposition lines is not associated.",ERR,ERROR,*999)
    DECOMPOSITION_ELEMENTS=>TOPOLOGY%ELEMENTS
    IF(.NOT.ASSOCIATED(DECOMPOSITION_ELEMENTS)) CALL FlagError("decomposition elements is not associated.",ERR,ERROR,*999)
    DECOMPOSITION=>TOPOLOGY%DECOMPOSITION
    IF(.NOT.ASSOCIATED(DECOMPOSITION)) CALL FlagError("Decomposition is not associated.",ERR,ERROR,*999)
    DOMAIN=>DECOMPOSITION%DOMAIN(DECOMPOSITION%MESH_COMPONENT_NUMBER)%PTR
    IF(.NOT.ASSOCIATED(DOMAIN)) CALL FlagError("Domain is not associated.",ERR,ERROR,*999)
    DOMAIN_TOPOLOGY=>DOMAIN%TOPOLOGY
    IF(.NOT.ASSOCIATED(DOMAIN_TOPOLOGY)) CALL FlagError("Domain Topology is not associated.",ERR,ERROR,*999)
    DOMAIN_MAPPINGS=>DOMAIN%MAPPINGS
    IF(.NOT.ASSOCIATED(DOMAIN_MAPPINGS)) CALL FlagError("Domain mappings is not associated.",ERR,ERROR,*999)
    ELEMENTS_MAPPING=>DOMAIN_MAPPINGS%ELEMENTS
    IF(.NOT.ASSOCIATED(ELEMENTS_MAPPING)) CALL FlagError("Elements mapping is not associated.",ERR,ERROR,*999)
    LINES_MAPPING=>DOMAIN_MAPPINGS%LINES
    IF(.NOT.ASSOCIATED(LINES_MAPPING)) CALL FlagError("Lines mapping is not associated.",ERR,ERROR,*999)
    DOMAIN_NODES=>DOMAIN_TOPOLOGY%NODES
    IF(.NOT.ASSOCIATED(DOMAIN_NODES)) CALL FlagError("domain nodes is not associated.",ERR,ERROR,*999)
    DOMAIN_LINES=>DOMAIN_TOPOLOGY%LINES
    IF(.NOT.ASSOCIATED(DOMAIN_LINES)) CALL FlagError("domain lines is not associated.",ERR,ERROR,*999)
    DOMAIN_ELEMENTS=>DOMAIN_TOPOLOGY%ELEMENTS
    IF(.NOT.ASSOCIATED(DOMAIN_ELEMENTS)) CALL FlagError("domain elements is not associated.",ERR,ERROR,*999)
    componentIdx=domain%MESH_COMPONENT_NUMBER
    MESH_TOPOLOGY=>DOMAIN%MESH%topology(componentIdx)%PTR
    IF(.NOT.ASSOCIATED(MESH_TOPOLOGY)) CALL FlagError("mesh topology is not associated.",ERR,ERROR,*999)


    !determine start Nic for basis directions, i.e quads have (-3,-2,-1,1,2,3), tets have (1,2,3,4)
    SELECT CASE(MESH_TOPOLOGY%ELEMENTS%ELEMENTS(1)%BASIS%TYPE)!Assumes all elements have the same basis
    CASE(BASIS_SIMPLEX_TYPE)
      startNic=1
    CASE(BASIS_LAGRANGE_HERMITE_TP_TYPE)
      IF(DECOMPOSITION%numberOfDimensions == 1) THEN
        startNic=1
      ELSE
        startNic=-MESH_TOPOLOGY%ELEMENTS%ELEMENTS(1)%BASIS%NUMBER_OF_XI_COORDINATES
      ENDIF
    CASE DEFAULT
      CALL FlagError("The basis type is not yet implemented",ERR,ERROR,*999)
    END SELECT

    ALLOCATE(TEMP_LINES(4,LINES_MAPPING%TOTAL_NUMBER_OF_LOCAL),STAT=ERR)
    IF(ERR/=0) CALL FlagError("Could not allocate temporary lines array.",ERR,ERROR,*999)
    ALLOCATE(NODES_NUMBER_OF_LINES(DOMAIN_NODES%TOTAL_NUMBER_OF_NODES),STAT=ERR)
    IF(ERR/=0) CALL FlagError("Could not allocate nodes number of lines array.",ERR,ERROR,*999)
    NODES_NUMBER_OF_LINES=0
    TEMP_LINES=0


    !Loop over the elements in the topology
    DO elementLocalNo=1,DOMAIN_ELEMENTS%TOTAL_NUMBER_OF_ELEMENTS
      DOMAIN_ELEMENT=>DOMAIN_ELEMENTS%ELEMENTS(elementLocalNo)
      DECOMPOSITION_ELEMENT=>DECOMPOSITION_ELEMENTS%ELEMENTS(elementLocalNo)
      BASIS=>DOMAIN_ELEMENT%BASIS
      ALLOCATE(DECOMPOSITION_ELEMENT%ELEMENT_LINES(BASIS%NUMBER_OF_LOCAL_LINES),STAT=ERR)
      IF(ERR/=0) CALL FlagError("Could not allocate element lines.",ERR,ERROR,*999)

      elementGlobalNo = ELEMENTS_MAPPING%LOCAL_TO_GLOBAL_MAP(elementLocalNo)

      DO xicIdx = startNic,MESH_TOPOLOGY%ELEMENTS%ELEMENTS(elementGlobalNo)%BASIS%NUMBER_OF_XI_COORDINATES
        IF(xicIdx ==0) CYCLE

        SELECT CASE(DECOMPOSITION%numberOfDimensions)
        CASE(1)
          lineBasisLocalNo=1
        CASE(2)
          lineBasisLocalNo=BASIS%xiNormalsLocalLine(xicIdx,1)
        ENDSELECT

        NODES_IN_LINE=0
        DO basis_local_line_node_idx=1,BASIS%NUMBER_OF_NODES_IN_LOCAL_LINE(lineBasisLocalNo)
          NODES_IN_LINE(basis_local_line_node_idx)=DOMAIN_ELEMENT%ELEMENT_NODES( &
            & BASIS%NODE_NUMBERS_IN_LOCAL_LINE(basis_local_line_node_idx,lineBasisLocalNo))
        ENDDO !basis_local_line_node_idx

        !Try and find a previously created line that matches in the adjacent elements
        FOUND=.FALSE.
        node_idx=NODES_IN_LINE(1)
        DO elem_idx=1,DOMAIN_NODES%NODES(node_idx)%NUMBER_OF_SURROUNDING_ELEMENTS
          surroundingElementLocalNo=DOMAIN_NODES%NODES(node_idx)%SURROUNDING_ELEMENTS(elem_idx)
          IF(surroundingElementLocalNo/=elementLocalNo) THEN
            IF(ALLOCATED(DECOMPOSITION_ELEMENTS%ELEMENTS(surroundingElementLocalNo)%ELEMENT_LINES)) THEN
              BASIS2=>DOMAIN_ELEMENTS%ELEMENTS(surroundingElementLocalNo)%BASIS
              DO surrounding_element_basis_local_line_idx=1,BASIS2%NUMBER_OF_LOCAL_LINES
                local_line_idx=DECOMPOSITION_ELEMENTS%ELEMENTS(surroundingElementLocalNo)% &
                  & ELEMENT_LINES(surrounding_element_basis_local_line_idx)
                IF(ALL(NODES_IN_LINE(1:BASIS%NUMBER_OF_NODES_IN_LOCAL_LINE(lineBasisLocalNo))== &
                  & TEMP_LINES(1:BASIS%NUMBER_OF_NODES_IN_LOCAL_LINE(lineBasisLocalNo),local_line_idx))) THEN
                  FOUND=.TRUE.
                  EXIT
                ENDIF
              ENDDO !surrounding_element_basis_local_line_idx
              IF(FOUND) EXIT
            ENDIF
          ENDIF
        ENDDO !elem_idx

        IF(FOUND) THEN
          !Line has already been created
          DECOMPOSITION_ELEMENT%ELEMENT_LINES(lineBasisLocalNo)=local_line_idx
        ELSE

          lineGlobalNo=MESH_TOPOLOGY%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_LINES(xicIdx)

          !Find the line local number
          DO lineIdx = 1,LINES_MAPPING%TOTAL_NUMBER_OF_LOCAL
            lineGlobalNo2 = LINES_MAPPING%LOCAL_TO_GLOBAL_MAP(lineIdx)

            IF(lineGlobalNo == lineGlobalNo2) THEN
              lineLocalNo=lineIdx
              EXIT
            ENDIF
          ENDDO !lineIdx
          DECOMPOSITION_ELEMENT%ELEMENT_LINES(lineBasisLocalNo)=lineLocalNo
          TEMP_LINES(:,lineLocalNo)=NODES_IN_LINE

          DO basis_local_line_node_idx=1,SIZE(NODES_IN_LINE,1)
            IF(NODES_IN_LINE(basis_local_line_node_idx)/=0) &
              & NODES_NUMBER_OF_LINES(NODES_IN_LINE(basis_local_line_node_idx))= &
              & NODES_NUMBER_OF_LINES(NODES_IN_LINE(basis_local_line_node_idx))+1
          ENDDO !basis_local_line_node_idx

        ENDIF
      ENDDO !xicIdx
    ENDDO !elementLocalNo

    !Allocate the line arrays and set them from the LINES and NODE_LINES arrays
    DO node_idx=1,DOMAIN_NODES%TOTAL_NUMBER_OF_NODES
      ALLOCATE(DOMAIN_NODES%NODES(node_idx)%NODE_LINES(NODES_NUMBER_OF_LINES(node_idx)),STAT=ERR)
      IF(ERR/=0) CALL FlagError("Could not allocate node lines array.",ERR,ERROR,*999)
      DOMAIN_NODES%NODES(node_idx)%NUMBER_OF_NODE_LINES=0
    ENDDO !node_idx
    DEALLOCATE(NODES_NUMBER_OF_LINES)
    ALLOCATE(DECOMPOSITION_LINES%LINES(LINES_MAPPING%TOTAL_NUMBER_OF_LOCAL),STAT=ERR)
    IF(ERR/=0) CALL FlagError("Could not allocate decomposition topology lines.",ERR,ERROR,*999)
    DECOMPOSITION_LINES%NUMBER_OF_LINES=LINES_MAPPING%TOTAL_NUMBER_OF_LOCAL
    ALLOCATE(DOMAIN_LINES%LINES(LINES_MAPPING%TOTAL_NUMBER_OF_LOCAL),STAT=ERR)
    IF(ERR/=0) CALL FlagError("Could not allocate domain topology lines.",ERR,ERROR,*999)
    DOMAIN_LINES%NUMBER_OF_LINES=LINES_MAPPING%TOTAL_NUMBER_OF_LOCAL
    DO local_line_idx=1,DOMAIN_LINES%NUMBER_OF_LINES
      CALL DECOMPOSITION_TOPOLOGY_LINE_INITIALISE(DECOMPOSITION_LINES%LINES(local_line_idx),ERR,ERROR,*999)
      CALL DOMAIN_TOPOLOGY_LINE_INITIALISE(DOMAIN_LINES%LINES(local_line_idx),ERR,ERROR,*999)
      DO basis_local_line_node_idx=1,SIZE(TEMP_LINES,1)
        IF(TEMP_LINES(basis_local_line_node_idx,local_line_idx)/=0) THEN
          node_idx=TEMP_LINES(basis_local_line_node_idx,local_line_idx)
          DOMAIN_NODES%NODES(node_idx)%NUMBER_OF_NODE_LINES=DOMAIN_NODES%NODES(node_idx)%NUMBER_OF_NODE_LINES+1
          DOMAIN_NODES%NODES(node_idx)%NODE_LINES(DOMAIN_NODES%NODES(node_idx)%NUMBER_OF_NODE_LINES)= &
            & local_line_idx
        ENDIF
      ENDDO !basis_local_line_node_idx
    ENDDO !local_line_idx
    DO element_idx=1,DECOMPOSITION_ELEMENTS%TOTAL_NUMBER_OF_ELEMENTS
      DECOMPOSITION_ELEMENT=>DECOMPOSITION_ELEMENTS%ELEMENTS(element_idx)
      DOMAIN_ELEMENT=>DOMAIN_ELEMENTS%ELEMENTS(element_idx)
      BASIS=>DOMAIN_ELEMENT%BASIS
      DO basis_local_line_idx=1,BASIS%NUMBER_OF_LOCAL_LINES
        LINE_NUMBER=DECOMPOSITION_ELEMENT%ELEMENT_LINES(basis_local_line_idx)
        DECOMPOSITION_LINE=>DECOMPOSITION_LINES%LINES(LINE_NUMBER)
        DOMAIN_LINE=>DOMAIN_LINES%LINES(LINE_NUMBER)
        DECOMPOSITION_LINE%NUMBER_OF_SURROUNDING_ELEMENTS=DECOMPOSITION_LINE%NUMBER_OF_SURROUNDING_ELEMENTS+1
        IF(.NOT.ASSOCIATED(DOMAIN_LINE%BASIS)) THEN
          DECOMPOSITION_LINE%NUMBER=LINE_NUMBER
          DOMAIN_LINE%NUMBER=LINE_NUMBER
          DOMAIN_LINE%ELEMENT_NUMBER=element_idx !Needs checking
          DECOMPOSITION_LINE%XI_DIRECTION=BASIS%localLineXiDirection(basis_local_line_idx)
          IF(ALLOCATED(BASIS%localLineBasis)) THEN
            DOMAIN_LINE%BASIS=>BASIS%localLineBasis(basis_local_line_idx)%PTR
          ELSE
            !Basis is only 1D
            DOMAIN_LINE%BASIS=>BASIS
          ENDIF
          ALLOCATE(DOMAIN_LINE%NODES_IN_LINE(BASIS%NUMBER_OF_NODES_IN_LOCAL_LINE(basis_local_line_idx)),STAT=ERR)
          IF(ERR/=0) CALL FlagError("Could not allocate line nodes in line.",ERR,ERROR,*999)
          ALLOCATE(DOMAIN_LINE%DERIVATIVES_IN_LINE(2,DOMAIN_LINE%BASIS%MAXIMUM_NUMBER_OF_DERIVATIVES, &
            & BASIS%NUMBER_OF_NODES_IN_LOCAL_LINE(basis_local_line_idx)),STAT=ERR)
          IF(ERR/=0) CALL FlagError("Could not allocate line derivatives in line.",ERR,ERROR,*999)
          DOMAIN_LINE%NODES_IN_LINE(1:BASIS%NUMBER_OF_NODES_IN_LOCAL_LINE(basis_local_line_idx))= &
            & TEMP_LINES(1:BASIS%NUMBER_OF_NODES_IN_LOCAL_LINE(basis_local_line_idx),LINE_NUMBER)
          DO basis_local_line_node_idx=1,BASIS%NUMBER_OF_NODES_IN_LOCAL_LINE(basis_local_line_idx)
            !Set derivative number of u (NO_GLOBAL_DERIV) for the domain line
            DOMAIN_LINE%DERIVATIVES_IN_LINE(1,1,basis_local_line_node_idx)=NO_GLOBAL_DERIV
            !Set version number of u (NO_GLOBAL_DERIV) for the domain line
            version_idx=DOMAIN_ELEMENT%elementVersions(1,BASIS%NODE_NUMBERS_IN_LOCAL_LINE( &
              & basis_local_line_node_idx,basis_local_line_idx))
            DOMAIN_LINE%DERIVATIVES_IN_LINE(2,1,basis_local_line_node_idx)=version_idx
            IF(DOMAIN_LINE%BASIS%MAXIMUM_NUMBER_OF_DERIVATIVES>1) THEN
              derivative_idx=DOMAIN_ELEMENT%ELEMENT_DERIVATIVES( &
                & BASIS%DERIVATIVE_NUMBERS_IN_LOCAL_LINE(basis_local_line_node_idx,basis_local_line_idx), &
                & BASIS%NODE_NUMBERS_IN_LOCAL_LINE(basis_local_line_node_idx,basis_local_line_idx))
              DOMAIN_LINE%DERIVATIVES_IN_LINE(1,2,basis_local_line_node_idx)=derivative_idx
              version_idx=DOMAIN_ELEMENT%elementVersions(BASIS%DERIVATIVE_NUMBERS_IN_LOCAL_LINE( &
                & basis_local_line_node_idx,basis_local_line_idx),BASIS%NODE_NUMBERS_IN_LOCAL_LINE( &
                & basis_local_line_node_idx,basis_local_line_idx))
              DOMAIN_LINE%DERIVATIVES_IN_LINE(2,2,basis_local_line_node_idx)=version_idx
            ENDIF
          ENDDO !basis_local_line_node_idx
        ENDIF
      ENDDO !basis_local_line_idx
    ENDDO !element_idx
    DEALLOCATE(TEMP_LINES)
    !Calculate adjacent lines and the surrounding elements for each line
    DO local_line_idx=1,DECOMPOSITION_LINES%NUMBER_OF_LINES
      DECOMPOSITION_LINE=>DECOMPOSITION_LINES%LINES(local_line_idx)
      DOMAIN_LINE=>DOMAIN_LINES%LINES(local_line_idx)
      BASIS=>DOMAIN_LINE%BASIS

      ! IF(DECOMPOSITION_LINE%NUMBER_OF_SURROUNDING_ELEMENTS==1) THEN
      ! This has been changed so that lines on boundary plane between two domains isn't counted as a boundary line
      lineGlobalNo = LINES_MAPPING%LOCAL_TO_GLOBAL_MAP(local_line_idx)
      IF(MESH_TOPOLOGY%lines%lines(lineGlobalNo)%externalLine) THEN
        DECOMPOSITION_LINE%BOUNDARY_LINE=.TRUE.
        DOMAIN_LINE%BOUNDARY_LINE=.TRUE.
      ENDIF
      !Allocate the elements surrounding the line
      ALLOCATE(DECOMPOSITION_LINE%SURROUNDING_ELEMENTS(DECOMPOSITION_LINE%NUMBER_OF_SURROUNDING_ELEMENTS), &
        & STAT=ERR)
      IF(ERR/=0) CALL FlagError("Could not allocate line surrounding elements.",ERR,ERROR,*999)
      ALLOCATE(DECOMPOSITION_LINE%ELEMENT_LINES(DECOMPOSITION_LINE%NUMBER_OF_SURROUNDING_ELEMENTS), &
        & STAT=ERR)
      IF(ERR/=0) CALL FlagError("Could not allocate line element lines.",ERR,ERROR,*999)
      DECOMPOSITION_LINE%NUMBER_OF_SURROUNDING_ELEMENTS=0
      DECOMPOSITION_LINE%ADJACENT_LINES=0
      !Loop over the nodes at each end of the line
      DO line_end_node_idx=0,1
        FOUND=.FALSE.
        node_idx=DOMAIN_LINE%NODES_IN_LINE(line_end_node_idx*(BASIS%NUMBER_OF_NODES-1)+1)
        !Loop over the elements surrounding the node.
        DO elem_idx=1,DOMAIN_NODES%NODES(node_idx)%NUMBER_OF_SURROUNDING_ELEMENTS
          element_idx=DOMAIN_NODES%NODES(node_idx)%SURROUNDING_ELEMENTS(elem_idx)
          DECOMPOSITION_ELEMENT=>DECOMPOSITION_ELEMENTS%ELEMENTS(element_idx)
          DOMAIN_ELEMENT=>DOMAIN_ELEMENTS%ELEMENTS(element_idx)
          !Loop over the local lines of the element
          DO basis_local_line_idx=1,DOMAIN_ELEMENT%BASIS%NUMBER_OF_LOCAL_LINES
            surrounding_element_local_line_idx=DECOMPOSITION_ELEMENT%ELEMENT_LINES(basis_local_line_idx)
            IF(surrounding_element_local_line_idx/=local_line_idx) THEN
              DECOMPOSITION_LINE2=>DECOMPOSITION_LINES%LINES(surrounding_element_local_line_idx)
              DOMAIN_LINE2=>DOMAIN_LINES%LINES(surrounding_element_local_line_idx)
              IF(DECOMPOSITION_LINE2%XI_DIRECTION==DECOMPOSITION_LINE%XI_DIRECTION) THEN
                !Lines run in the same direction.
                BASIS2=>DOMAIN_LINE2%BASIS
                IF(line_end_node_idx==0) THEN
                  local_node_idx=DOMAIN_LINE2%NODES_IN_LINE(BASIS2%NUMBER_OF_NODES)
                ELSE
                  local_node_idx=DOMAIN_LINE2%NODES_IN_LINE(1)
                ENDIF
                IF(local_node_idx==node_idx) THEN
                  !The node at the 'other' end of this line matches the node at the current end of the line.
                  !Check it is not a coexistant line running the other way
                  IF(BASIS2%INTERPOLATION_ORDER(1)==BASIS%INTERPOLATION_ORDER(1)) THEN
                    COUNT=0
                    DO basis_node_idx=1,BASIS%NUMBER_OF_NODES
                      IF(DOMAIN_LINE2%NODES_IN_LINE(basis_node_idx)== &
                        & DOMAIN_LINE%NODES_IN_LINE(BASIS2%NUMBER_OF_NODES-basis_node_idx+1)) &
                        & COUNT=COUNT+1
                    ENDDO !basis_node_idx
                    IF(COUNT<BASIS%NUMBER_OF_NODES) THEN
                      FOUND=.TRUE.
                      EXIT
                    ENDIF
                  ELSE
                    FOUND=.TRUE.
                    EXIT
                  ENDIF
                ENDIF
              ENDIF
            ENDIF
          ENDDO !basis_local_line_idx
          IF(FOUND) EXIT
        ENDDO !element_idx
        IF(FOUND) DECOMPOSITION_LINE%ADJACENT_LINES(line_end_node_idx)=surrounding_element_local_line_idx
      ENDDO !line_end_node_idx
    ENDDO !local_line_idx
    !Set the surrounding elements
    DO element_idx=1,DECOMPOSITION_ELEMENTS%TOTAL_NUMBER_OF_ELEMENTS
      DECOMPOSITION_ELEMENT=>DECOMPOSITION_ELEMENTS%ELEMENTS(element_idx)
      DOMAIN_ELEMENT=>DOMAIN_ELEMENTS%ELEMENTS(element_idx)
      BASIS=>DOMAIN_ELEMENT%BASIS
      DO basis_local_line_idx=1,BASIS%NUMBER_OF_LOCAL_LINES
        LINE_NUMBER=DECOMPOSITION_ELEMENT%ELEMENT_LINES(basis_local_line_idx)
        DECOMPOSITION_LINE=>DECOMPOSITION_LINES%LINES(LINE_NUMBER)
        DECOMPOSITION_LINE%NUMBER_OF_SURROUNDING_ELEMENTS=DECOMPOSITION_LINE%NUMBER_OF_SURROUNDING_ELEMENTS+1
        DECOMPOSITION_LINE%SURROUNDING_ELEMENTS(DECOMPOSITION_LINE%NUMBER_OF_SURROUNDING_ELEMENTS)=element_idx
        DECOMPOSITION_LINE%ELEMENT_LINES(DECOMPOSITION_LINE%NUMBER_OF_SURROUNDING_ELEMENTS)=basis_local_line_idx
      ENDDO !basis_local_line_idx
    ENDDO !element_idx

    !Now loop over the other mesh components in the decomposition and calculate the domain lines
    MESH=>DECOMPOSITION%MESH
    IF(ASSOCIATED(MESH)) THEN
      DO component_idx=1,MESH%NUMBER_OF_COMPONENTS
        IF(component_idx/=DECOMPOSITION%MESH_COMPONENT_NUMBER) THEN
          DOMAIN=>DECOMPOSITION%DOMAIN(component_idx)%PTR
          IF(ASSOCIATED(DOMAIN)) THEN
            DOMAIN_TOPOLOGY=>DOMAIN%TOPOLOGY
            IF(ASSOCIATED(DOMAIN_TOPOLOGY)) THEN
              DOMAIN_NODES=>DOMAIN_TOPOLOGY%NODES
              IF(ASSOCIATED(DOMAIN_NODES)) THEN
                DOMAIN_ELEMENTS=>DOMAIN_TOPOLOGY%ELEMENTS
                IF(ASSOCIATED(DOMAIN_ELEMENTS)) THEN
                  DOMAIN_LINES=>DOMAIN_TOPOLOGY%LINES
                  IF(ASSOCIATED(DOMAIN_LINES)) THEN
                    ALLOCATE(DOMAIN_LINES%LINES(DECOMPOSITION_LINES%NUMBER_OF_LINES),STAT=ERR)
                    IF(ERR/=0) CALL FlagError("Could not allocate domain lines lines.",ERR,ERROR,*999)
                    DOMAIN_LINES%NUMBER_OF_LINES=DECOMPOSITION_LINES%NUMBER_OF_LINES
                    ALLOCATE(NODES_NUMBER_OF_LINES(DOMAIN_NODES%TOTAL_NUMBER_OF_NODES),STAT=ERR)
                    IF(ERR/=0) CALL FlagError("Could not allocate nodes number of lines array.",ERR,ERROR,*999)
                    NODES_NUMBER_OF_LINES=0
                    !Loop over the lines in the topology
                    DO local_line_idx=1,DECOMPOSITION_LINES%NUMBER_OF_LINES
                      DECOMPOSITION_LINE=>DECOMPOSITION_LINES%LINES(local_line_idx)
                      DOMAIN_LINE=>DOMAIN_LINES%LINES(local_line_idx)
                      IF(DECOMPOSITION_LINE%NUMBER_OF_SURROUNDING_ELEMENTS>0) THEN
                        element_idx=DECOMPOSITION_LINE%SURROUNDING_ELEMENTS(1)
                        basis_local_line_idx=DECOMPOSITION_LINE%ELEMENT_LINES(1)
                        CALL DOMAIN_TOPOLOGY_LINE_INITIALISE(DOMAIN_LINES%LINES(local_line_idx),ERR,ERROR,*999)
                        DOMAIN_LINE%NUMBER=local_line_idx
                        DOMAIN_ELEMENT=>DOMAIN_ELEMENTS%ELEMENTS(element_idx)
                        BASIS=>DOMAIN_ELEMENT%BASIS
                        DOMAIN_LINE%ELEMENT_NUMBER=DOMAIN_ELEMENT%NUMBER
                        IF(ALLOCATED(BASIS%localLineBasis)) THEN
                          DOMAIN_LINE%BASIS=>BASIS%localLineBasis(basis_local_line_idx)%PTR
                        ELSE
                          !Basis is only 1D
                          DOMAIN_LINE%BASIS=>BASIS
                        ENDIF
                        ALLOCATE(DOMAIN_LINE%NODES_IN_LINE(BASIS%NUMBER_OF_NODES_IN_LOCAL_LINE(basis_local_line_idx)), &
                          & STAT=ERR)
                        IF(ERR/=0) CALL FlagError("Could not allocate nodes in line.",ERR,ERROR,*999)
                        ALLOCATE(DOMAIN_LINE%DERIVATIVES_IN_LINE(2,DOMAIN_LINE%BASIS%MAXIMUM_NUMBER_OF_DERIVATIVES, &
                          & BASIS%NUMBER_OF_NODES_IN_LOCAL_LINE(basis_local_line_idx)),STAT=ERR)
                        IF(ERR/=0) CALL FlagError("Could not allocate derivatives in line.",ERR,ERROR,*999)
                        DO basis_local_line_node_idx=1,BASIS%NUMBER_OF_NODES_IN_LOCAL_LINE(basis_local_line_idx)
                          element_local_node_idx=BASIS%NODE_NUMBERS_IN_LOCAL_LINE(basis_local_line_node_idx, &
                            & basis_local_line_idx)
                          node_idx=DOMAIN_ELEMENT%ELEMENT_NODES(element_local_node_idx)
                          DOMAIN_LINE%NODES_IN_LINE(basis_local_line_node_idx)=node_idx
                          !Set derivative number of u (NO_GLOBAL_DERIV) for the domain line
                          DOMAIN_LINE%DERIVATIVES_IN_LINE(1,1,basis_local_line_node_idx)=NO_GLOBAL_DERIV
                          !Set version number of u (NO_GLOBAL_DERIV) for the domain line
                          version_idx=DOMAIN_ELEMENT%elementVersions(1,BASIS%NODE_NUMBERS_IN_LOCAL_LINE( &
                            & basis_local_line_node_idx,basis_local_line_idx))
                          DOMAIN_LINE%DERIVATIVES_IN_LINE(2,1,basis_local_line_node_idx)=version_idx
                          IF(DOMAIN_LINE%BASIS%MAXIMUM_NUMBER_OF_DERIVATIVES>1) THEN
                            derivative_idx=DOMAIN_ELEMENT%ELEMENT_DERIVATIVES(BASIS%DERIVATIVE_NUMBERS_IN_LOCAL_LINE( &
                              & basis_local_line_node_idx,basis_local_line_idx),element_local_node_idx)
                            DOMAIN_LINE%DERIVATIVES_IN_LINE(1,2,basis_local_line_node_idx)=derivative_idx
                            version_idx=DOMAIN_ELEMENT%elementVersions(BASIS%DERIVATIVE_NUMBERS_IN_LOCAL_LINE( &
                              & basis_local_line_node_idx,basis_local_line_idx),BASIS%NODE_NUMBERS_IN_LOCAL_LINE( &
                              & basis_local_line_node_idx,basis_local_line_idx))
                            DOMAIN_LINE%DERIVATIVES_IN_LINE(2,2,basis_local_line_node_idx)=version_idx
                          ENDIF
                          NODES_NUMBER_OF_LINES(node_idx)=NODES_NUMBER_OF_LINES(node_idx)+1
                        ENDDO !basis_local_line_node_idx
                      ELSE
                        CALL FlagError("Line is not surrounded by any elements?",ERR,ERROR,*999)
                      ENDIF
                    ENDDO !local_line_idx
                    DO node_idx=1,DOMAIN_NODES%TOTAL_NUMBER_OF_NODES
                      ALLOCATE(DOMAIN_NODES%NODES(node_idx)%NODE_LINES(NODES_NUMBER_OF_LINES(node_idx)),STAT=ERR)
                      IF(ERR/=0) CALL FlagError("Could not allocate node lines.",ERR,ERROR,*999)
                      DOMAIN_NODES%NODES(node_idx)%NUMBER_OF_NODE_LINES=0
                    ENDDO !node_idx
                    DEALLOCATE(NODES_NUMBER_OF_LINES)
                    DO local_line_idx=1,DOMAIN_LINES%NUMBER_OF_LINES
                      DOMAIN_LINE=>DOMAIN_LINES%LINES(local_line_idx)
                      BASIS=>DOMAIN_LINE%BASIS
                      DO basis_local_line_node_idx=1,BASIS%NUMBER_OF_NODES
                        node_idx=DOMAIN_LINE%NODES_IN_LINE(basis_local_line_node_idx)
                        DOMAIN_NODE=>DOMAIN_NODES%NODES(node_idx)
                        DOMAIN_NODE%NUMBER_OF_NODE_LINES=DOMAIN_NODE%NUMBER_OF_NODE_LINES+1
                        DOMAIN_NODE%NODE_LINES(DOMAIN_NODE%NUMBER_OF_NODE_LINES)=local_line_idx
                      ENDDO !basis_local_line_node_idx
                    ENDDO !local_line_idx
                  ELSE
                    CALL FlagError("Domain lines is not associated.",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FlagError("Domain elements is not associated.",ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FlagError("Domain nodes is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FlagError("Domain topology is not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Decomposition mesh is not associated",ERR,ERROR,*999)
          ENDIF
        ENDIF
      ENDDO !component_idx
    ELSE
      CALL FlagError("Decomposition mesh is not associated.",ERR,ERROR,*999)
    ENDIF

    IF(DIAGNOSTICS1) THEN
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"Decomposition topology lines:",ERR,ERROR,*999)
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  Number of mesh components = ",MESH%NUMBER_OF_COMPONENTS,ERR,ERROR,*999)
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  Number of lines = ",DECOMPOSITION_LINES%NUMBER_OF_LINES,ERR,ERROR,*999)
      DO local_line_idx=1,DECOMPOSITION_LINES%NUMBER_OF_LINES
        DECOMPOSITION_LINE=>DECOMPOSITION_LINES%LINES(local_line_idx)
        DOMAIN_LINE=>DOMAIN_LINES%LINES(local_line_idx)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Line number = ",DECOMPOSITION_LINE%NUMBER,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Xi direction = ",DECOMPOSITION_LINE%XI_DIRECTION,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Number of surrounding elements = ", &
          & DECOMPOSITION_LINE%NUMBER_OF_SURROUNDING_ELEMENTS,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,DECOMPOSITION_LINE%NUMBER_OF_SURROUNDING_ELEMENTS,4,4, &
          & DECOMPOSITION_LINE%SURROUNDING_ELEMENTS,'("      Surrounding elements :",4(X,I8))','(28X,4(X,I8))',ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,DECOMPOSITION_LINE%NUMBER_OF_SURROUNDING_ELEMENTS,4,4, &
          & DECOMPOSITION_LINE%ELEMENT_LINES,'("      Element lines        :",4(X,I8))','(28X,4(X,I8))',ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,2,2,2,DECOMPOSITION_LINE%ADJACENT_LINES, &
          & '("      Adjacent lines       :",2(X,I8))','(28X,2(X,I8))',ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Boundary line = ",DECOMPOSITION_LINE%BOUNDARY_LINE,ERR,ERROR,*999)
        DO component_idx=1,MESH%NUMBER_OF_COMPONENTS
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Mesh component : ",component_idx,ERR,ERROR,*999)
          DOMAIN=>DECOMPOSITION%DOMAIN(component_idx)%PTR
          DOMAIN_LINE=>DOMAIN%TOPOLOGY%LINES%LINES(local_line_idx)
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"        Basis user number = ",DOMAIN_LINE%BASIS%USER_NUMBER, &
            & ERR,ERROR,*999)
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"        Basis family number = ",DOMAIN_LINE%BASIS%FAMILY_NUMBER, &
            & ERR,ERROR,*999)
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"        Basis interpolation type = ",DOMAIN_LINE%BASIS% &
            & INTERPOLATION_TYPE(1),ERR,ERROR,*999)
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"        Basis interpolation order = ",DOMAIN_LINE%BASIS% &
            & INTERPOLATION_ORDER(1),ERR,ERROR,*999)
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"        Number of nodes in lines = ",DOMAIN_LINE%BASIS%NUMBER_OF_NODES, &
            & ERR,ERROR,*999)
          CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,DOMAIN_LINE%BASIS%NUMBER_OF_NODES,4,4,DOMAIN_LINE%NODES_IN_LINE, &
            & '("        Nodes in line        :",4(X,I8))','(30X,4(X,I8))',ERR,ERROR,*999)
          DO basis_local_line_node_idx=1,DOMAIN_LINE%BASIS%NUMBER_OF_NODES
            CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"          Node : ",basis_local_line_node_idx,ERR,ERROR,*999)
            !/TODO::Loop over local_derivative index so this output makes more sense !<DERIVATIVES_IN_LINE(i,local_derivative_idx,local_node_idx)
            CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1, &
              & DOMAIN_LINE%BASIS%NUMBER_OF_DERIVATIVES(basis_local_line_node_idx),4,4, &
              & DOMAIN_LINE%DERIVATIVES_IN_LINE(1,:,basis_local_line_node_idx),'("            Derivatives in line  :",4(X,I8))', &
              & '(34X,4(X,I8))',ERR,ERROR,*999)
            CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1, &
              & DOMAIN_LINE%BASIS%NUMBER_OF_DERIVATIVES(basis_local_line_node_idx),4,4, &
              & DOMAIN_LINE%DERIVATIVES_IN_LINE(2,:,basis_local_line_node_idx), &
              & '("            Derivatives Versions in line  :",4(X,I8))','(34X,4(X,I8))',ERR,ERROR,*999)
          ENDDO !basis_local_line_node_idx
        ENDDO !component_idx
      ENDDO !local_line_idx
    ENDIF

    EXITS("DECOMPOSITION_TOPOLOGY_LINES_CALCULATE")
    RETURN
999 IF(ASSOCIATED(TEMP_LINES)) DEALLOCATE(TEMP_LINES)
    IF(ASSOCIATED(NEW_TEMP_LINES)) DEALLOCATE(NEW_TEMP_LINES)
    IF(ALLOCATED(NODES_NUMBER_OF_LINES)) DEALLOCATE(NODES_NUMBER_OF_LINES)
    ERRORSEXITS("DECOMPOSITION_TOPOLOGY_LINES_CALCULATE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_TOPOLOGY_LINES_CALCULATE

  !
  !================================================================================================================================
  !

  !>Finalises the lines in the given decomposition topology. \todo Pass in the topology lines
  SUBROUTINE DECOMPOSITION_TOPOLOGY_LINES_FINALISE(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the decomposition topology to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: nl

    ENTERS("DECOMPOSITION_TOPOLOGY_LINES_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      IF(ASSOCIATED(TOPOLOGY%LINES)) THEN
        DO nl=1,TOPOLOGY%LINES%NUMBER_OF_LINES
          CALL DECOMPOSITION_TOPOLOGY_LINE_FINALISE(TOPOLOGY%LINES%LINES(nl),ERR,ERROR,*999)
        ENDDO !nl
        IF(ALLOCATED(TOPOLOGY%LINES%LINES)) DEALLOCATE(TOPOLOGY%LINES%LINES)
        DEALLOCATE(TOPOLOGY%LINES)
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_TOPOLOGY_LINES_FINALISE")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_TOPOLOGY_LINES_FINALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_TOPOLOGY_LINES_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the line data structures for a decomposition topology.
  SUBROUTINE DECOMPOSITION_TOPOLOGY_LINES_INITIALISE(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the decomposition topology to initialise the lines for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DECOMPOSITION_TOPOLOGY_LINES_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      IF(ASSOCIATED(TOPOLOGY%LINES)) THEN
        CALL FlagError("Decomposition already has topology lines associated.",ERR,ERROR,*999)
      ELSE
        ALLOCATE(TOPOLOGY%LINES,STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate topology lines.",ERR,ERROR,*999)
        TOPOLOGY%LINES%NUMBER_OF_LINES=0
        TOPOLOGY%LINES%DECOMPOSITION=>TOPOLOGY%DECOMPOSITION
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_TOPOLOGY_LINES_INITIALISE")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_TOPOLOGY_LINES_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_TOPOLOGY_LINES_INITIALISE

  !
  !================================================================================================================================
  !

  !>Initialises the line data structures for a decomposition topology.
  SUBROUTINE DecompositionTopology_DataPointsInitialise(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the decomposition topology to initialise the lines for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DecompositionTopology_DataPointsInitialise",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      IF(ASSOCIATED(TOPOLOGY%dataPoints)) THEN
        CALL FlagError("Decomposition already has topology data points associated.",ERR,ERROR,*999)
      ELSE
        ALLOCATE(TOPOLOGY%dataPoints,STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate topology data points.",ERR,ERROR,*999)
        TOPOLOGY%dataPoints%numberOfDataPoints=0
        TOPOLOGY%dataPoints%totalNumberOfDataPoints=0
        TOPOLOGY%dataPoints%numberOfGlobalDataPoints=0
        NULLIFY(TOPOLOGY%dataPoints%dataPointsTree)
        TOPOLOGY%dataPoints%DECOMPOSITION=>TOPOLOGY%DECOMPOSITION
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DecompositionTopology_DataPointsInitialise")
    RETURN
999 ERRORSEXITS("DecompositionTopology_DataPointsInitialise",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DecompositionTopology_DataPointsInitialise

  !
  !================================================================================================================================
  !

  !>Finalises a face in the given decomposition topology and deallocates all memory.
  SUBROUTINE DECOMPOSITION_TOPOLOGY_FACE_FINALISE(FACE,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_FACE_TYPE) :: FACE !<The decomposition face to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DECOMPOSITION_TOPOLOGY_FACE_FINALISE",ERR,ERROR,*999)

    FACE%NUMBER=0
    FACE%XI_DIRECTION=0
    FACE%NUMBER_OF_SURROUNDING_ELEMENTS=0
    IF(ALLOCATED(FACE%SURROUNDING_ELEMENTS)) DEALLOCATE(FACE%SURROUNDING_ELEMENTS)
    IF(ALLOCATED(FACE%ELEMENT_FACES)) DEALLOCATE(FACE%ELEMENT_FACES)
!    FACE%ADJACENT_FACES=0

    EXITS("DECOMPOSITION_TOPOLOGY_FACE_FINALISE")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_TOPOLOGY_FACE_FINALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_TOPOLOGY_FACE_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the face data structure for a decomposition topology face.
  SUBROUTINE DECOMPOSITION_TOPOLOGY_FACE_INITIALISE(FACE,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_FACE_TYPE) :: FACE !<The decomposition face to initialise.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DECOMPOSITION_TOPOLOGY_FACE_INITIALISE",ERR,ERROR,*999)

    FACE%NUMBER=0
    FACE%XI_DIRECTION=0
    FACE%NUMBER_OF_SURROUNDING_ELEMENTS=0
!    FACE%ADJACENT_FACES=0
    FACE%BOUNDARY_FACE=.FALSE.

    EXITS("DECOMPOSITION_TOPOLOGY_FACE_INITIALISE")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_TOPOLOGY_FACE_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_TOPOLOGY_FACE_INITIALISE

  !
  !================================================================================================================================
  !

  !>Calculates the faces in the given decomposition topology.
  SUBROUTINE DECOMPOSITION_TOPOLOGY_FACES_CALCULATE(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the decomposition topology to calculate the faces for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: component_idx,ne, basis_local_face_idx,surrounding_element_basis_local_face_idx, &
      & element_local_node_idx,basis_local_face_node_idx,basis_local_face_derivative_idx,derivative_idx,version_idx,face_idx, &
      & node_idx,elem_idx,NODES_IN_FACE(16),FACE_NUMBER, startNic, xicIdx,elementLocalNo, surroundingElementLocalNo, &
      & elementGlobalNo, componentIdx, faceBasisLocalNo, faceGlobalNo, faceGlobalNo2, faceIdx, faceLocalNo, local_face_idx, &
      & element_idx
    INTEGER(INTG), ALLOCATABLE :: NODES_NUMBER_OF_FACES(:)
    INTEGER(INTG), POINTER :: TEMP_FACES(:,:),NEW_TEMP_FACES(:,:)
    LOGICAL :: FOUND
    TYPE(BASIS_TYPE), POINTER :: BASIS,BASIS2
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION
    TYPE(DECOMPOSITION_ELEMENT_TYPE), POINTER :: DECOMPOSITION_ELEMENT
    TYPE(DECOMPOSITION_ELEMENTS_TYPE), POINTER :: DECOMPOSITION_ELEMENTS
    TYPE(DECOMPOSITION_FACE_TYPE), POINTER :: DECOMPOSITION_FACE!,DECOMPOSITION_FACE2
    TYPE(DECOMPOSITION_FACES_TYPE), POINTER :: DECOMPOSITION_FACES
    TYPE(DOMAIN_TYPE), POINTER :: DOMAIN
    TYPE(DOMAIN_ELEMENT_TYPE), POINTER :: DOMAIN_ELEMENT
    TYPE(DOMAIN_ELEMENTS_TYPE), POINTER :: DOMAIN_ELEMENTS
    TYPE(DOMAIN_FACE_TYPE), POINTER :: DOMAIN_FACE!,DOMAIN_FACE2
    TYPE(DOMAIN_FACES_TYPE), POINTER :: DOMAIN_FACES
    TYPE(DOMAIN_NODE_TYPE), POINTER :: DOMAIN_NODE
    TYPE(DOMAIN_NODES_TYPE), POINTER :: DOMAIN_NODES
    TYPE(DOMAIN_TOPOLOGY_TYPE), POINTER :: DOMAIN_TOPOLOGY
    TYPE(DOMAIN_MAPPINGS_TYPE), POINTER :: DOMAIN_MAPPINGS
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: ELEMENTS_MAPPING, FACES_MAPPING
    TYPE(MESH_TYPE), POINTER :: MESH
    TYPE(MeshComponentTopologyType), POINTER :: MESH_TOPOLOGY

    NULLIFY(TEMP_FACES)
    NULLIFY(NEW_TEMP_FACES)

    ENTERS("DECOMPOSITION_TOPOLOGY_FACES_CALCULATE",ERR,ERROR,*999)


    IF(.NOT.ASSOCIATED(TOPOLOGY)) CALL FlagError("Topology is not associated.",ERR,ERROR,*999)
    DECOMPOSITION_FACES=>TOPOLOGY%FACES
    IF(.NOT.ASSOCIATED(DECOMPOSITION_FACES)) CALL FlagError("decomposition faces is not associated.",ERR,ERROR,*999)
    DECOMPOSITION_ELEMENTS=>TOPOLOGY%ELEMENTS
    IF(.NOT.ASSOCIATED(DECOMPOSITION_ELEMENTS)) CALL FlagError("decomposition elements is not associated.",ERR,ERROR,*999)
    DECOMPOSITION=>TOPOLOGY%DECOMPOSITION
    IF(.NOT.ASSOCIATED(DECOMPOSITION)) CALL FlagError("Decomposition is not associated.",ERR,ERROR,*999)
    DOMAIN=>DECOMPOSITION%DOMAIN(DECOMPOSITION%MESH_COMPONENT_NUMBER)%PTR
    IF(.NOT.ASSOCIATED(DOMAIN)) CALL FlagError("Domain is not associated.",ERR,ERROR,*999)
    DOMAIN_TOPOLOGY=>DOMAIN%TOPOLOGY
    IF(.NOT.ASSOCIATED(DOMAIN_TOPOLOGY)) CALL FlagError("Domain Topology is not associated.",ERR,ERROR,*999)
    DOMAIN_MAPPINGS=>DOMAIN%MAPPINGS
    IF(.NOT.ASSOCIATED(DOMAIN_MAPPINGS)) CALL FlagError("Domain mappings is not associated.",ERR,ERROR,*999)
    ELEMENTS_MAPPING=>DOMAIN_MAPPINGS%ELEMENTS
    IF(.NOT.ASSOCIATED(ELEMENTS_MAPPING)) CALL FlagError("Elements mapping is not associated.",ERR,ERROR,*999)
    FACES_MAPPING=>DOMAIN_MAPPINGS%FACES
    IF(.NOT.ASSOCIATED(FACES_MAPPING)) CALL FlagError("Faces mapping is not associated.",ERR,ERROR,*999)
    DOMAIN_NODES=>DOMAIN_TOPOLOGY%NODES
    IF(.NOT.ASSOCIATED(DOMAIN_NODES)) CALL FlagError("domain nodes is not associated.",ERR,ERROR,*999)
    DOMAIN_FACES=>DOMAIN_TOPOLOGY%FACES
    IF(.NOT.ASSOCIATED(DOMAIN_FACES)) CALL FlagError("domain faces is not associated.",ERR,ERROR,*999)
    DOMAIN_ELEMENTS=>DOMAIN_TOPOLOGY%ELEMENTS
    IF(.NOT.ASSOCIATED(DOMAIN_ELEMENTS)) CALL FlagError("domain elements is not associated.",ERR,ERROR,*999)
    componentIdx=domain%MESH_COMPONENT_NUMBER
    MESH_TOPOLOGY=>DOMAIN%MESH%topology(componentIdx)%PTR
    IF(.NOT.ASSOCIATED(MESH_TOPOLOGY)) CALL FlagError("mesh topology is not associated.",ERR,ERROR,*999)


    !determine start Nic for basis directions, i.e quads have (-3,-2,-1,1,2,3), tets have (1,2,3,4)
    SELECT CASE(MESH_TOPOLOGY%ELEMENTS%ELEMENTS(1)%BASIS%TYPE)!Assumes all elements have the same basis
    CASE(BASIS_SIMPLEX_TYPE)
      startNic=1
    CASE(BASIS_LAGRANGE_HERMITE_TP_TYPE)
      IF(DECOMPOSITION%numberOfDimensions == 1) THEN
        startNic=1
      ELSE
        startNic=-MESH_TOPOLOGY%ELEMENTS%ELEMENTS(1)%BASIS%NUMBER_OF_XI_COORDINATES
      ENDIF
    CASE DEFAULT
      CALL FlagError("The basis type is not yet implemented",ERR,ERROR,*999)
    END SELECT


    SELECT CASE(DOMAIN%NUMBER_OF_DIMENSIONS)
    CASE(1)
      ! Faces not calculated in 1D
    CASE(2)
      ! Faces not calculated in 2D
    CASE(3)

      ALLOCATE(TEMP_FACES(16,FACES_MAPPING%TOTAL_NUMBER_OF_LOCAL),STAT=ERR)
      IF(ERR/=0) CALL FlagError("Could not allocate temporary faces array",ERR,ERROR,*999)
      ALLOCATE(NODES_NUMBER_OF_FACES(DOMAIN_NODES%TOTAL_NUMBER_OF_NODES),STAT=ERR)
      IF(ERR/=0) CALL FlagError("Could not allocate nodes number of faces array",ERR,ERROR,*999)
      NODES_NUMBER_OF_FACES=0
      TEMP_FACES=0
      !Loop over the elements in the topology
      DO elementLocalNo=1,DOMAIN_ELEMENTS%TOTAL_NUMBER_OF_ELEMENTS
        DOMAIN_ELEMENT=>DOMAIN_ELEMENTS%ELEMENTS(elementLocalNo)
        DECOMPOSITION_ELEMENT=>DECOMPOSITION_ELEMENTS%ELEMENTS(elementLocalNo)
        BASIS=>DOMAIN_ELEMENT%BASIS
        ALLOCATE(DECOMPOSITION_ELEMENT%ELEMENT_FACES(BASIS%NUMBER_OF_LOCAL_FACES),STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate element faces.",ERR,ERROR,*999)

        elementGlobalNo = ELEMENTS_MAPPING%LOCAL_TO_GLOBAL_MAP(elementLocalNo)

        DO xicIdx = startNic,MESH_TOPOLOGY%ELEMENTS%ELEMENTS(elementGlobalNo)%BASIS%NUMBER_OF_XI_COORDINATES
          IF(xicIdx ==0) CYCLE
          IF(MESH_TOPOLOGY%ELEMENTS%ELEMENTS(1)%BASIS%TYPE == BASIS_LAGRANGE_HERMITE_TP_TYPE) THEN
            IF(xicIdx<0) THEN
              IF(BASIS%COLLAPSED_XI(abs(xicIdx))==BASIS_COLLAPSED_AT_XI0) CYCLE
            ELSE
              IF(BASIS%COLLAPSED_XI(xicIdx)==BASIS_COLLAPSED_AT_XI1) CYCLE
            ENDIF
          ENDIF

          faceBasisLocalNo=BASIS%xiNormalLocalFace(xicIdx)

          NODES_IN_FACE=0
          DO basis_local_face_node_idx=1,BASIS%NUMBER_OF_NODES_IN_LOCAL_FACE(faceBasisLocalNo)
            NODES_IN_FACE(basis_local_face_node_idx)=DOMAIN_ELEMENT%ELEMENT_NODES( &
              & BASIS%NODE_NUMBERS_IN_LOCAL_FACE(basis_local_face_node_idx,faceBasisLocalNo))
          ENDDO !basis_local_face_node_idx

          !Try and find a previously created face that matches in the adjacent elements
          FOUND=.FALSE.
          node_idx=NODES_IN_FACE(1)
          DO elem_idx=1,DOMAIN_NODES%NODES(node_idx)%NUMBER_OF_SURROUNDING_ELEMENTS
            surroundingElementLocalNo=DOMAIN_NODES%NODES(node_idx)%SURROUNDING_ELEMENTS(elem_idx)
            IF(surroundingElementLocalNo/=elementLocalNo) THEN
              IF(ALLOCATED(DECOMPOSITION_ELEMENTS%ELEMENTS(surroundingElementLocalNo)%ELEMENT_FACES)) THEN
                BASIS2=>DOMAIN_ELEMENTS%ELEMENTS(surroundingElementLocalNo)%BASIS
                DO surrounding_element_basis_local_face_idx=1,BASIS2%NUMBER_OF_LOCAL_FACES
                  local_face_idx=DECOMPOSITION_ELEMENTS%ELEMENTS(surroundingElementLocalNo)% &
                    & ELEMENT_FACES(surrounding_element_basis_local_face_idx)
                  IF(ALL(NODES_IN_FACE(1:BASIS%NUMBER_OF_NODES_IN_LOCAL_FACE(faceBasisLocalNo))== &
                    & TEMP_FACES(1:BASIS%NUMBER_OF_NODES_IN_LOCAL_FACE(faceBasisLocalNo),local_face_idx))) THEN
                    FOUND=.TRUE.
                    EXIT
                  ENDIF
                ENDDO !surrounding_element_basis_local_face_idx
                IF(FOUND) EXIT
              ENDIF
            ENDIF
          ENDDO !elem_idx

          IF(FOUND) THEN
            !Face has already been created
            DECOMPOSITION_ELEMENT%ELEMENT_FACES(faceBasisLocalNo)=local_face_idx
          ELSE

            faceGlobalNo=MESH_TOPOLOGY%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_FACES(xicIdx)

            !Find the face local number
            DO faceIdx = 1,FACES_MAPPING%TOTAL_NUMBER_OF_LOCAL
              faceGlobalNo2 = FACES_MAPPING%LOCAL_TO_GLOBAL_MAP(faceIdx)

              IF(faceGlobalNo == faceGlobalNo2) THEN
                faceLocalNo=faceIdx
                EXIT
              ENDIF
            ENDDO !faceIdx
            DECOMPOSITION_ELEMENT%ELEMENT_FACES(faceBasisLocalNo)=faceLocalNo
            TEMP_FACES(:,faceLocalNo)=NODES_IN_FACE

            DO basis_local_face_node_idx=1,SIZE(NODES_IN_FACE,1)
              IF(NODES_IN_FACE(basis_local_face_node_idx)/=0) &
                & NODES_NUMBER_OF_FACES(NODES_IN_FACE(basis_local_face_node_idx))= &
                & NODES_NUMBER_OF_FACES(NODES_IN_FACE(basis_local_face_node_idx))+1
            ENDDO !basis_local_face_node_idx

          ENDIF
        ENDDO !xicIdx
      ENDDO !elementLocalNo

      !Allocate the face arrays and set them from the FACES and NODE_FACES arrays
      DO node_idx=1,DOMAIN_NODES%TOTAL_NUMBER_OF_NODES
        ALLOCATE(DOMAIN_NODES%NODES(node_idx)%NODE_FACES(NODES_NUMBER_OF_FACES(node_idx)),STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate node faces array.",ERR,ERROR,*999)
        DOMAIN_NODES%NODES(node_idx)%NUMBER_OF_NODE_FACES=0
      ENDDO !node_idx
      DEALLOCATE(NODES_NUMBER_OF_FACES)
      ALLOCATE(DECOMPOSITION_FACES%FACES(FACES_MAPPING%TOTAL_NUMBER_OF_LOCAL),STAT=ERR)
      IF(ERR/=0) CALL FlagError("Could not allocate decomposition topology faces.",ERR,ERROR,*999)
      DECOMPOSITION_FACES%NUMBER_OF_FACES=FACES_MAPPING%TOTAL_NUMBER_OF_LOCAL
      ALLOCATE(DOMAIN_FACES%FACES(FACES_MAPPING%TOTAL_NUMBER_OF_LOCAL),STAT=ERR)
      IF(ERR/=0) CALL FlagError("Could not allocate domain topology faces.",ERR,ERROR,*999)
      DOMAIN_FACES%NUMBER_OF_FACES=FACES_MAPPING%TOTAL_NUMBER_OF_LOCAL
      DO local_face_idx=1,DOMAIN_FACES%NUMBER_OF_FACES
        CALL DECOMPOSITION_TOPOLOGY_FACE_INITIALISE(DECOMPOSITION_FACES%FACES(local_face_idx),ERR,ERROR,*999)
        CALL DOMAIN_TOPOLOGY_FACE_INITIALISE(DOMAIN_FACES%FACES(local_face_idx),ERR,ERROR,*999)
        DO basis_local_face_node_idx=1,SIZE(TEMP_FACES,1)
          IF(TEMP_FACES(basis_local_face_node_idx,local_face_idx)/=0) THEN
            node_idx=TEMP_FACES(basis_local_face_node_idx,local_face_idx)
            DOMAIN_NODES%NODES(node_idx)%NUMBER_OF_NODE_FACES=DOMAIN_NODES%NODES(node_idx)%NUMBER_OF_NODE_FACES+1
            DOMAIN_NODES%NODES(node_idx)%NODE_FACES(DOMAIN_NODES%NODES(node_idx)%NUMBER_OF_NODE_FACES)= &
              & local_face_idx
          ENDIF
        ENDDO !basis_local_face_node_idx
      ENDDO !local_face_idx
      DO element_idx=1,DECOMPOSITION_ELEMENTS%TOTAL_NUMBER_OF_ELEMENTS
        DECOMPOSITION_ELEMENT=>DECOMPOSITION_ELEMENTS%ELEMENTS(element_idx)
        DOMAIN_ELEMENT=>DOMAIN_ELEMENTS%ELEMENTS(element_idx)
        BASIS=>DOMAIN_ELEMENT%BASIS
        DO basis_local_face_idx=1,BASIS%NUMBER_OF_LOCAL_FACES
          FACE_NUMBER=DECOMPOSITION_ELEMENT%ELEMENT_FACES(basis_local_face_idx)
          DECOMPOSITION_FACE=>DECOMPOSITION_FACES%FACES(FACE_NUMBER)
          DOMAIN_FACE=>DOMAIN_FACES%FACES(FACE_NUMBER)
          DECOMPOSITION_FACE%NUMBER_OF_SURROUNDING_ELEMENTS=DECOMPOSITION_FACE%NUMBER_OF_SURROUNDING_ELEMENTS+1
          IF(.NOT.ASSOCIATED(DOMAIN_FACE%BASIS)) THEN
            DECOMPOSITION_FACE%NUMBER=FACE_NUMBER
            DOMAIN_FACE%NUMBER=FACE_NUMBER
            DOMAIN_FACE%ELEMENT_NUMBER=element_idx !Needs checking
            DECOMPOSITION_FACE%XI_DIRECTION=BASIS%localFaceXiNormal(basis_local_face_idx)
            IF(ALLOCATED(BASIS%localFaceBasis)) THEN
              DOMAIN_FACE%BASIS=>BASIS%localFaceBasis(basis_local_face_idx)%PTR
            ELSE
              !Basis is only 1D
              DOMAIN_FACE%BASIS=>BASIS
            ENDIF
            ALLOCATE(DOMAIN_FACE%NODES_IN_FACE(BASIS%NUMBER_OF_NODES_IN_LOCAL_FACE(basis_local_face_idx)),STAT=ERR)
            IF(ERR/=0) CALL FlagError("Could not allocate face nodes in face.",ERR,ERROR,*999)
            ALLOCATE(DOMAIN_FACE%DERIVATIVES_IN_FACE(2,DOMAIN_FACE%BASIS%MAXIMUM_NUMBER_OF_DERIVATIVES, &
              & BASIS%NUMBER_OF_NODES_IN_LOCAL_FACE(basis_local_face_idx)),STAT=ERR)
            IF(ERR/=0) CALL FlagError("Could not allocate face derivatives in face.",ERR,ERROR,*999)
            DOMAIN_FACE%NODES_IN_FACE(1:BASIS%NUMBER_OF_NODES_IN_LOCAL_FACE(basis_local_face_idx))= &
              & TEMP_FACES(1:BASIS%NUMBER_OF_NODES_IN_LOCAL_FACE(basis_local_face_idx),FACE_NUMBER)
            DO basis_local_face_node_idx=1,BASIS%NUMBER_OF_NODES_IN_LOCAL_FACE(basis_local_face_idx)
              element_local_node_idx=BASIS%NODE_NUMBERS_IN_LOCAL_FACE(basis_local_face_node_idx, &
                & basis_local_face_idx)
              !Set derivative number of u (NO_GLOBAL_DERIV) for the domain face
              DOMAIN_FACE%DERIVATIVES_IN_FACE(1,1,basis_local_face_node_idx)=NO_GLOBAL_DERIV
              !Set version number of u (NO_GLOBAL_DERIV) for the domain face
              version_idx=DOMAIN_ELEMENT%elementVersions(1,BASIS%NODE_NUMBERS_IN_LOCAL_FACE( &
                & basis_local_face_node_idx,basis_local_face_idx))
              DOMAIN_FACE%DERIVATIVES_IN_FACE(2,1,basis_local_face_node_idx)=version_idx
              IF(DOMAIN_FACE%BASIS%MAXIMUM_NUMBER_OF_DERIVATIVES>1) THEN
                DO basis_local_face_derivative_idx=2,DOMAIN_FACE%BASIS%MAXIMUM_NUMBER_OF_DERIVATIVES
                  derivative_idx=DOMAIN_ELEMENT%ELEMENT_DERIVATIVES(BASIS%DERIVATIVE_NUMBERS_IN_LOCAL_FACE( &
                    & basis_local_face_derivative_idx,basis_local_face_node_idx,basis_local_face_idx), &
                    & element_local_node_idx)
                  DOMAIN_FACE%DERIVATIVES_IN_FACE(1,basis_local_face_derivative_idx, &
                    & basis_local_face_node_idx)=derivative_idx
                  version_idx=DOMAIN_ELEMENT%elementVersions(BASIS%DERIVATIVE_NUMBERS_IN_LOCAL_FACE( &
                    & basis_local_face_derivative_idx,basis_local_face_node_idx,basis_local_face_idx), &
                    & element_local_node_idx)
                  DOMAIN_FACE%DERIVATIVES_IN_FACE(2,basis_local_face_derivative_idx, &
                    & basis_local_face_node_idx)=version_idx
                ENDDO !basis_local_face_derivative_idx
              ENDIF
            ENDDO !basis_local_face_node_idx
          ENDIF
        ENDDO !basis_local_face_idx
      ENDDO !element_idx
      DEALLOCATE(TEMP_FACES)
      !Calculate adjacent faces and the surrounding elements for each face
      DO local_face_idx=1,DECOMPOSITION_FACES%NUMBER_OF_FACES
        DECOMPOSITION_FACE=>DECOMPOSITION_FACES%FACES(local_face_idx)
        DOMAIN_FACE=>DOMAIN_FACES%FACES(local_face_idx)
        BASIS=>DOMAIN_FACE%BASIS

        ! IF(DECOMPOSITION_FACE%NUMBER_OF_SURROUNDING_ELEMENTS==1) THEN
        ! This has been changed so that faces on boundary plane between two domains isn't counted as a boundary face
        faceGlobalNo = FACES_MAPPING%LOCAL_TO_GLOBAL_MAP(local_face_idx)
        IF(MESH_TOPOLOGY%faces%faces(faceGlobalNo)%externalFace) THEN
          DECOMPOSITION_FACE%BOUNDARY_FACE=.TRUE.
          DOMAIN_FACE%BOUNDARY_FACE=.TRUE.
        ENDIF
        !Allocate the elements surrounding the face
        ALLOCATE(DECOMPOSITION_FACE%SURROUNDING_ELEMENTS(DECOMPOSITION_FACE%NUMBER_OF_SURROUNDING_ELEMENTS), &
          & STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate face surrounding elements.",ERR,ERROR,*999)
        ALLOCATE(DECOMPOSITION_FACE%ELEMENT_FACES(DECOMPOSITION_FACE%NUMBER_OF_SURROUNDING_ELEMENTS), &
          & STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate face element faces.",ERR,ERROR,*999)
      !   DECOMPOSITION_FACE%NUMBER_OF_SURROUNDING_ELEMENTS=0
      !   DECOMPOSITION_FACE%ADJACENT_FACES=0
      !   !Loop over the nodes at each end of the face
      !   DO face_end_node_idx=0,1
      !     FOUND=.FALSE.
      !     node_idx=DOMAIN_FACE%NODES_IN_FACE(face_end_node_idx*(BASIS%NUMBER_OF_NODES-1)+1)
      !     !Loop over the elements surrounding the node.
      !     DO elem_idx=1,DOMAIN_NODES%NODES(node_idx)%NUMBER_OF_SURROUNDING_ELEMENTS
      !       element_idx=DOMAIN_NODES%NODES(node_idx)%SURROUNDING_ELEMENTS(elem_idx)
      !       DECOMPOSITION_ELEMENT=>DECOMPOSITION_ELEMENTS%ELEMENTS(element_idx)
      !       DOMAIN_ELEMENT=>DOMAIN_ELEMENTS%ELEMENTS(element_idx)
      !       !Loop over the local faces of the element
      !       DO basis_local_face_idx=1,DOMAIN_ELEMENT%BASIS%NUMBER_OF_LOCAL_FACES
      !         surrounding_element_local_face_idx=DECOMPOSITION_ELEMENT%ELEMENT_FACES(basis_local_face_idx)
      !         IF(surrounding_element_local_face_idx/=local_face_idx) THEN
      !           DECOMPOSITION_FACE2=>DECOMPOSITION_FACES%FACES(surrounding_element_local_face_idx)
      !           DOMAIN_FACE2=>DOMAIN_FACES%FACES(surrounding_element_local_face_idx)
      !           IF(DECOMPOSITION_FACE2%XI_DIRECTION==DECOMPOSITION_FACE%XI_DIRECTION) THEN
      !             !Faces run in the same direction.
      !             BASIS2=>DOMAIN_FACE2%BASIS
      !             IF(face_end_node_idx==0) THEN
      !               local_node_idx=DOMAIN_FACE2%NODES_IN_FACE(BASIS2%NUMBER_OF_NODES)
      !             ELSE
      !               local_node_idx=DOMAIN_FACE2%NODES_IN_FACE(1)
      !             ENDIF
      !             IF(local_node_idx==node_idx) THEN
      !               !The node at the 'other' end of this face matches the node at the current end of the face.
      !               !Check it is not a coexistant face running the other way
      !               IF(BASIS2%INTERPOLATION_ORDER(1)==BASIS%INTERPOLATION_ORDER(1)) THEN
      !                 COUNT=0
      !                 DO basis_node_idx=1,BASIS%NUMBER_OF_NODES
      !                   IF(DOMAIN_FACE2%NODES_IN_FACE(basis_node_idx)== &
      !                     & DOMAIN_FACE%NODES_IN_FACE(BASIS2%NUMBER_OF_NODES-basis_node_idx+1)) &
      !                     & COUNT=COUNT+1
      !                 ENDDO !basis_node_idx
      !                 IF(COUNT<BASIS%NUMBER_OF_NODES) THEN
      !                   FOUND=.TRUE.
      !                   EXIT
      !                 ENDIF
      !               ELSE
      !                 FOUND=.TRUE.
      !                 EXIT
      !               ENDIF
      !             ENDIF
      !           ENDIF
      !         ENDIF
      !       ENDDO !basis_local_face_idx
      !       IF(FOUND) EXIT
      !     ENDDO !element_idx
      !     IF(FOUND) DECOMPOSITION_FACE%ADJACENT_FACES(face_end_node_idx)=surrounding_element_local_face_idx
      !   ENDDO !face_end_node_idx
      ENDDO !local_face_idx

      !Set the surrounding elements
      DO element_idx=1,DECOMPOSITION_ELEMENTS%TOTAL_NUMBER_OF_ELEMENTS
        DECOMPOSITION_ELEMENT=>DECOMPOSITION_ELEMENTS%ELEMENTS(element_idx)
        DOMAIN_ELEMENT=>DOMAIN_ELEMENTS%ELEMENTS(element_idx)
        BASIS=>DOMAIN_ELEMENT%BASIS
        DO basis_local_face_idx=1,BASIS%NUMBER_OF_LOCAL_FACES
          FACE_NUMBER=DECOMPOSITION_ELEMENT%ELEMENT_FACES(basis_local_face_idx)
          DECOMPOSITION_FACE=>DECOMPOSITION_FACES%FACES(FACE_NUMBER)
          DO face_idx=1,DECOMPOSITION_FACE%NUMBER_OF_SURROUNDING_ELEMENTS
            DECOMPOSITION_FACE%SURROUNDING_ELEMENTS(face_idx)=element_idx
            DECOMPOSITION_FACE%ELEMENT_FACES(face_idx)=basis_local_face_idx
          ENDDO
        ENDDO !basis_local_face_idx
      ENDDO !element_idx

    CASE DEFAULT
      CALL FlagError("Invalid number of dimensions for a topology domain",ERR,ERROR,*999)
    END SELECT

    !Now loop over the other mesh components in the decomposition and calculate the domain faces
    MESH=>DECOMPOSITION%MESH
    IF(ASSOCIATED(MESH)) THEN
      DO component_idx=1,MESH%NUMBER_OF_COMPONENTS
        IF(component_idx/=DECOMPOSITION%MESH_COMPONENT_NUMBER) THEN
          DOMAIN=>DECOMPOSITION%DOMAIN(component_idx)%PTR
          IF(ASSOCIATED(DOMAIN)) THEN
            DOMAIN_TOPOLOGY=>DOMAIN%TOPOLOGY
            IF(ASSOCIATED(DOMAIN_TOPOLOGY)) THEN
              DOMAIN_NODES=>DOMAIN_TOPOLOGY%NODES
              IF(ASSOCIATED(DOMAIN_NODES)) THEN
                DOMAIN_ELEMENTS=>DOMAIN_TOPOLOGY%ELEMENTS
                IF(ASSOCIATED(DOMAIN_ELEMENTS)) THEN
                  DOMAIN_FACES=>DOMAIN_TOPOLOGY%FACES
                  IF(ASSOCIATED(DOMAIN_FACES)) THEN
                    ALLOCATE(DOMAIN_FACES%FACES(DECOMPOSITION_FACES%NUMBER_OF_FACES),STAT=ERR)
                    IF(ERR/=0) CALL FlagError("Could not allocate domain faces faces",ERR,ERROR,*999)
                    DOMAIN_FACES%NUMBER_OF_FACES=DECOMPOSITION_FACES%NUMBER_OF_FACES
                    ALLOCATE(NODES_NUMBER_OF_FACES(DOMAIN_NODES%TOTAL_NUMBER_OF_NODES),STAT=ERR)
                    IF(ERR/=0) CALL FlagError("Could not allocate nodes number of faces array",ERR,ERROR,*999)
                    NODES_NUMBER_OF_FACES=0
                    !Loop over the faces in the topology
                    DO face_idx=1,DECOMPOSITION_FACES%NUMBER_OF_FACES
                      DECOMPOSITION_FACE=>DECOMPOSITION_FACES%FACES(face_idx)
                      DOMAIN_FACE=>DOMAIN_FACES%FACES(face_idx)
                      IF(DECOMPOSITION_FACE%NUMBER_OF_SURROUNDING_ELEMENTS>0) THEN
                        ne=DECOMPOSITION_FACE%SURROUNDING_ELEMENTS(1)
                        basis_local_face_idx=DECOMPOSITION_FACE%ELEMENT_FACES(1)
                        CALL DOMAIN_TOPOLOGY_FACE_INITIALISE(DOMAIN_FACES%FACES(face_idx),ERR,ERROR,*999)
                        DOMAIN_FACE%NUMBER=face_idx
                        DOMAIN_ELEMENT=>DOMAIN_ELEMENTS%ELEMENTS(ne)
                        BASIS=>DOMAIN_ELEMENT%BASIS
                        IF(ALLOCATED(BASIS%localFaceBasis)) THEN
                          DOMAIN_FACE%BASIS=>BASIS%localFaceBasis(basis_local_face_idx)%PTR
                        ELSE
                          !Basis is only 2D
                          DOMAIN_FACE%BASIS=>BASIS
                        ENDIF
                        ALLOCATE(DOMAIN_FACE%NODES_IN_FACE(BASIS%NUMBER_OF_NODES_IN_LOCAL_FACE(basis_local_face_idx)), &
                          & STAT=ERR)
                        IF(ERR/=0) CALL FlagError("Could not allocate nodes in face",ERR,ERROR,*999)
                        ALLOCATE(DOMAIN_FACE%DERIVATIVES_IN_FACE(2,DOMAIN_FACE%BASIS%MAXIMUM_NUMBER_OF_DERIVATIVES, &
                          & BASIS%NUMBER_OF_NODES_IN_LOCAL_FACE(basis_local_face_idx)),STAT=ERR)
                        IF(ERR/=0) CALL FlagError("Could not allocate derivatives in face",ERR,ERROR,*999)
                        !Set derivatives of nodes in domain face from derivatives of nodes in element
                        DO basis_local_face_node_idx=1,BASIS%NUMBER_OF_NODES_IN_LOCAL_FACE(basis_local_face_idx)
                          element_local_node_idx=BASIS%NODE_NUMBERS_IN_LOCAL_FACE(basis_local_face_node_idx, &
                            & basis_local_face_idx)
                          node_idx=DOMAIN_ELEMENT%ELEMENT_NODES(element_local_node_idx)
                          DOMAIN_FACE%NODES_IN_FACE(basis_local_face_node_idx)=node_idx
                          !Set derivative number of u (NO_GLOBAL_DERIV) for the domain face
                          DOMAIN_FACE%DERIVATIVES_IN_FACE(1,1,basis_local_face_node_idx)=NO_GLOBAL_DERIV
                          !Set version number of u (NO_GLOBAL_DERIV) for the domain face
                          version_idx=DOMAIN_ELEMENT%elementVersions(1,BASIS%NODE_NUMBERS_IN_LOCAL_FACE( &
                            & basis_local_face_node_idx,basis_local_face_idx))
                          DOMAIN_FACE%DERIVATIVES_IN_FACE(2,1,basis_local_face_node_idx)=version_idx
                          IF(DOMAIN_FACE%BASIS%MAXIMUM_NUMBER_OF_DERIVATIVES>1) THEN
                            DO basis_local_face_derivative_idx=2,DOMAIN_FACE%BASIS%MAXIMUM_NUMBER_OF_DERIVATIVES
                              derivative_idx=DOMAIN_ELEMENT%ELEMENT_DERIVATIVES(BASIS%DERIVATIVE_NUMBERS_IN_LOCAL_FACE( &
                                & basis_local_face_derivative_idx,basis_local_face_node_idx,basis_local_face_idx), &
                                & element_local_node_idx)
                              DOMAIN_FACE%DERIVATIVES_IN_FACE(1,basis_local_face_derivative_idx, &
                                & basis_local_face_node_idx)=derivative_idx
                              version_idx=DOMAIN_ELEMENT%elementVersions(BASIS%DERIVATIVE_NUMBERS_IN_LOCAL_FACE( &
                                & basis_local_face_derivative_idx,basis_local_face_node_idx,basis_local_face_idx), &
                                & element_local_node_idx)
                              DOMAIN_FACE%DERIVATIVES_IN_FACE(2,basis_local_face_derivative_idx, &
                                & basis_local_face_node_idx)=version_idx
                            ENDDO !basis_local_face_derivative_idx
                          ENDIF
                          NODES_NUMBER_OF_FACES(node_idx)=NODES_NUMBER_OF_FACES(node_idx)+1
                        ENDDO !basis_local_face_node_idx
                      ELSE
                        CALL FlagError("Face is not surrounded by any elements?",ERR,ERROR,*999)
                      ENDIF
                    ENDDO !face_idx
                    DO node_idx=1,DOMAIN_NODES%TOTAL_NUMBER_OF_NODES
                      ALLOCATE(DOMAIN_NODES%NODES(node_idx)%NODE_FACES(NODES_NUMBER_OF_FACES(node_idx)),STAT=ERR)
                      IF(ERR/=0) CALL FlagError("Could not allocate node faces",ERR,ERROR,*999)
                      DOMAIN_NODES%NODES(node_idx)%NUMBER_OF_NODE_FACES=0
                    ENDDO !node_idx
                    DEALLOCATE(NODES_NUMBER_OF_FACES)
                    DO face_idx=1,DOMAIN_FACES%NUMBER_OF_FACES
                      DOMAIN_FACE=>DOMAIN_FACES%FACES(face_idx)
                      BASIS=>DOMAIN_FACE%BASIS
                      DO basis_local_face_node_idx=1,BASIS%NUMBER_OF_NODES
                        node_idx=DOMAIN_FACE%NODES_IN_FACE(basis_local_face_node_idx)
                        DOMAIN_NODE=>DOMAIN_NODES%NODES(node_idx)
                        DOMAIN_NODE%NUMBER_OF_NODE_FACES=DOMAIN_NODE%NUMBER_OF_NODE_FACES+1
                        !Set the face numbers a node is on
                        DOMAIN_NODE%NODE_FACES(DOMAIN_NODE%NUMBER_OF_NODE_FACES)=face_idx
                      ENDDO !basis_local_face_node_idx
                    ENDDO !face_idx
                  ELSE
                    CALL FlagError("Domain faces is not associated",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FlagError("Domain elements is not associated",ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FlagError("Domain nodes is not associated",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FlagError("Domain topology is not associated",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Decomposition mesh is not associated",ERR,ERROR,*999)
          ENDIF
        ENDIF
      ENDDO !component_idx
    ELSE
      CALL FlagError("Decomposition mesh is not associated",ERR,ERROR,*999)
    ENDIF

    IF(DIAGNOSTICS1) THEN
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"Decomposition topology faces:",ERR,ERROR,*999)
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  Number of mesh components = ",MESH%NUMBER_OF_COMPONENTS,ERR,ERROR,*999)
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  Number of faces = ",DECOMPOSITION_FACES%NUMBER_OF_FACES,ERR,ERROR,*999)
      DO face_idx=1,DECOMPOSITION_FACES%NUMBER_OF_FACES
        DECOMPOSITION_FACE=>DECOMPOSITION_FACES%FACES(face_idx)
        DOMAIN_FACE=>DOMAIN_FACES%FACES(face_idx)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Face number = ",DECOMPOSITION_FACE%NUMBER,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Xi direction (Normal to Face) = &
                                                                         &",DECOMPOSITION_FACE%XI_DIRECTION,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Number of surrounding elements = ", &
          & DECOMPOSITION_FACE%NUMBER_OF_SURROUNDING_ELEMENTS,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,DECOMPOSITION_FACE%NUMBER_OF_SURROUNDING_ELEMENTS,4,4, &
          & DECOMPOSITION_FACE%SURROUNDING_ELEMENTS,'("      Surrounding elements :",4(X,I8))','(28X,4(X,I8))',ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,DECOMPOSITION_FACE%NUMBER_OF_SURROUNDING_ELEMENTS,4,4, &
          & DECOMPOSITION_FACE%ELEMENT_FACES,'("      Element faces        :",4(X,I8))','(28X,4(X,I8))',ERR,ERROR,*999)
!        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,2,2,2,DECOMPOSITION_FACE%ADJACENT_FACES, &
!          & '("      Adjacent faces       :",2(X,I8))','(28X,2(X,I8))',ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Boundary face = ",DECOMPOSITION_FACE%BOUNDARY_FACE,ERR,ERROR,*999)
        DO component_idx=1,MESH%NUMBER_OF_COMPONENTS
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Mesh component : ",component_idx,ERR,ERROR,*999)
          DOMAIN=>DECOMPOSITION%DOMAIN(component_idx)%PTR
          DOMAIN_FACE=>DOMAIN%TOPOLOGY%FACES%FACES(face_idx)
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"        Basis user number = ",DOMAIN_FACE%BASIS%USER_NUMBER, &
            & ERR,ERROR,*999)
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"        Basis family number = ",DOMAIN_FACE%BASIS%FAMILY_NUMBER, &
            & ERR,ERROR,*999)
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"        Basis interpolation type = ",DOMAIN_FACE%BASIS% &
            & INTERPOLATION_TYPE(1),ERR,ERROR,*999)
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"        Basis interpolation order = ",DOMAIN_FACE%BASIS% &
            & INTERPOLATION_ORDER(1),ERR,ERROR,*999)
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"        Number of nodes in faces = ",DOMAIN_FACE%BASIS%NUMBER_OF_NODES, &
            & ERR,ERROR,*999)
          CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,DOMAIN_FACE%BASIS%NUMBER_OF_NODES,4,4,DOMAIN_FACE%NODES_IN_FACE, &
            & '("        Nodes in face        :",4(X,I8))','(30X,4(X,I8))',ERR,ERROR,*999)
          DO basis_local_face_node_idx=1,DOMAIN_FACE%BASIS%NUMBER_OF_NODES
            CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"          Node : ",basis_local_face_node_idx,ERR,ERROR,*999)
            !/TODO::Loop over local_derivative index so this output makes more sense !<DERIVATIVES_IN_LINE(i,local_derivative_idx,local_node_idx)
            CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1, &
              & DOMAIN_FACE%BASIS%NUMBER_OF_DERIVATIVES(basis_local_face_node_idx),4,4,DOMAIN_FACE% &
              & DERIVATIVES_IN_FACE(1,:,basis_local_face_node_idx),'("            Derivatives in face  :",4(X,I8))', &
              & '(34X,4(X,I8))',ERR,ERROR,*999)
            CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1, &
              & DOMAIN_FACE%BASIS%NUMBER_OF_DERIVATIVES(basis_local_face_node_idx),4,4,DOMAIN_FACE% &
              & DERIVATIVES_IN_FACE(2,:,basis_local_face_node_idx),'("            Derivatives Versions in face  :",4(X,I8))', &
              & '(34X,4(X,I8))',ERR,ERROR,*999)
          ENDDO !basis_local_face_node_idx
        ENDDO !component_idx
      ENDDO !face_idx
    ENDIF

    EXITS("DECOMPOSITION_TOPOLOGY_FACES_CALCULATE")
    RETURN
999 IF(ASSOCIATED(TEMP_FACES)) DEALLOCATE(TEMP_FACES)
    IF(ASSOCIATED(NEW_TEMP_FACES)) DEALLOCATE(NEW_TEMP_FACES)
    IF(ALLOCATED(NODES_NUMBER_OF_FACES)) DEALLOCATE(NODES_NUMBER_OF_FACES)
    ERRORSEXITS("DECOMPOSITION_TOPOLOGY_FACES_CALCULATE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_TOPOLOGY_FACES_CALCULATE

  !
  !================================================================================================================================
  !

  !>Finalises the faces in the given decomposition topology.
  SUBROUTINE DECOMPOSITION_TOPOLOGY_FACES_FINALISE(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the decomposition topology to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: nf

    ENTERS("DECOMPOSITION_TOPOLOGY_FACES_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      IF(ASSOCIATED(TOPOLOGY%FACES)) THEN
        DO nf=1,TOPOLOGY%FACES%NUMBER_OF_FACES
          CALL DECOMPOSITION_TOPOLOGY_FACE_FINALISE(TOPOLOGY%FACES%FACES(nf),ERR,ERROR,*999)
        ENDDO !nf
        IF(ALLOCATED(TOPOLOGY%FACES%FACES)) DEALLOCATE(TOPOLOGY%FACES%FACES)
        DEALLOCATE(TOPOLOGY%FACES)
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_TOPOLOGY_FACES_FINALISE")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_TOPOLOGY_FACES_FINALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_TOPOLOGY_FACES_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the face data structures for a decomposition topology.
  SUBROUTINE DECOMPOSITION_TOPOLOGY_FACES_INITIALISE(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the decomposition topology to initialise the faces for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DECOMPOSITION_TOPOLOGY_FACES_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      IF(ASSOCIATED(TOPOLOGY%FACES)) THEN
        CALL FlagError("Decomposition already has topology faces associated",ERR,ERROR,*999)
      ELSE
        ALLOCATE(TOPOLOGY%FACES,STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate topology faces",ERR,ERROR,*999)
        TOPOLOGY%FACES%NUMBER_OF_FACES=0
        TOPOLOGY%FACES%DECOMPOSITION=>TOPOLOGY%DECOMPOSITION
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_TOPOLOGY_FACES_INITIALISE")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_TOPOLOGY_FACES_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_TOPOLOGY_FACES_INITIALISE

  !
  !================================================================================================================================
  !

  !>Gets the decomposition type for a decomposition. \see OPENCMISS::Iron::cmfe_DecompositionTypeGet
  SUBROUTINE DECOMPOSITION_TYPE_GET(DECOMPOSITION,TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION !<A pointer to the decomposition to get the type for
    INTEGER(INTG), INTENT(OUT) :: TYPE !<On return, the decomposition type for the specified decomposition \see MESH_ROUTINES_DecompositionTypes,MESH_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DECOMPOSITION_TYPE_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(DECOMPOSITION)) THEN
      IF(DECOMPOSITION%DECOMPOSITION_FINISHED) THEN
        TYPE=DECOMPOSITION%DECOMPOSITION_TYPE
      ELSE
        CALL FlagError("Decomposition has not finished.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Decomposition is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_TYPE_GET")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_TYPE_GET",ERR,ERROR)
    RETURN
  END SUBROUTINE DECOMPOSITION_TYPE_GET

  !
  !================================================================================================================================
  !

  !>Sets/changes the decomposition type for a decomposition.  \see OPENCMISS::Iron::cmfe_DecompositionTypeSet
  SUBROUTINE DECOMPOSITION_TYPE_SET(DECOMPOSITION,TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION !<A pointer to the decomposition to set the type for
    INTEGER(INTG), INTENT(IN) :: TYPE !<The decomposition type to set \see MESH_ROUTINES_DecompositionTypes,MESH_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("DECOMPOSITION_TYPE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(DECOMPOSITION)) THEN
      IF(DECOMPOSITION%DECOMPOSITION_FINISHED) THEN
        CALL FlagError("Decomposition has been finished.",ERR,ERROR,*999)
      ELSE
        SELECT CASE(TYPE)
        CASE(DECOMPOSITION_ALL_TYPE)
          !heye: three types for decomposition--decompostion_all_type means no decomposition
          DECOMPOSITION%DECOMPOSITION_TYPE=DECOMPOSITION_ALL_TYPE
        CASE(DECOMPOSITION_CALCULATED_TYPE)
          DECOMPOSITION%DECOMPOSITION_TYPE=DECOMPOSITION_CALCULATED_TYPE
        CASE(DECOMPOSITION_USER_DEFINED_TYPE)
          DECOMPOSITION%DECOMPOSITION_TYPE=DECOMPOSITION_USER_DEFINED_TYPE
        CASE DEFAULT
          LOCAL_ERROR="Decomposition type "//TRIM(NUMBER_TO_VSTRING(TYPE,"*",ERR,ERROR))//" is not valid."
          CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
        END SELECT
      ENDIF
    ELSE
      CALL FlagError("Decomposition is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_TYPE_SET")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_TYPE_SET",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_TYPE_SET

  !
  !================================================================================================================================
  !

  !>Sets/changes whether lines should be calculated in the the decomposition. \see OPENCMISS::Iron::cmfe_DecompositionCalculateLinesSet
  SUBROUTINE DECOMPOSITION_CALCULATE_LINES_SET(DECOMPOSITION,CALCULATE_LINES_FLAG,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION !<A pointer to the decomposition
    LOGICAL, INTENT(IN) :: CALCULATE_LINES_FLAG !<The boolean flag to determine whether the lines should be calculated or not
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string

    ENTERS("DECOMPOSITION_CALCULATE_LINES_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(DECOMPOSITION)) THEN
      IF(DECOMPOSITION%DECOMPOSITION_FINISHED) THEN
        CALL FlagError("Decomposition has been finished.",ERR,ERROR,*999)
      ELSE
        DECOMPOSITION%CALCULATE_LINES=CALCULATE_LINES_FLAG
      ENDIF
    ELSE
      CALL FlagError("Decomposition is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_CALCULATE_LINES_SET")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_CALCULATE_LINES_SET",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_CALCULATE_LINES_SET

  !
  !================================================================================================================================
  !

  !>Sets/changes whether faces should be calculated in the the decomposition. \see OPENCMISS::Iron::cmfe_DecompositionCalculateFacesSet
  SUBROUTINE DECOMPOSITION_CALCULATE_FACES_SET(DECOMPOSITION,CALCULATE_FACES_FLAG,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION !<A pointer to the decomposition
    LOGICAL, INTENT(IN) :: CALCULATE_FACES_FLAG !<The boolean flag to determine whether the faces should be calculated or not
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string

    ENTERS("DECOMPOSITION_CALCULATE_FACES_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(DECOMPOSITION)) THEN
      IF(DECOMPOSITION%DECOMPOSITION_FINISHED) THEN
        CALL FlagError("Decomposition has been finished.",ERR,ERROR,*999)
      ELSE
        DECOMPOSITION%CALCULATE_FACES=CALCULATE_FACES_FLAG
      ENDIF
    ELSE
      CALL FlagError("Decomposition is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_CALCULATE_FACES_SET")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_CALCULATE_FACES_SET",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_CALCULATE_FACES_SET

  !
  !================================================================================================================================
  !

  !>Sets/changes whether centroids should be calculated in the the decomposition. \see OPENCMISS::Iron::cmfe_DecompositionCalculateCentroidsSet
  SUBROUTINE DECOMPOSITION_CALCULATE_CENTROIDS_SET(DECOMPOSITION,CALCULATE_CENTROIDS_FLAG,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION !<A pointer to the decomposition
    LOGICAL, INTENT(IN) :: CALCULATE_CENTROIDS_FLAG !<The boolean flag to determine whether the centroids should be calculated or not
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string

    ENTERS("DECOMPOSITION_CALCULATE_CENTROIDS_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(DECOMPOSITION)) THEN
      IF(DECOMPOSITION%DECOMPOSITION_FINISHED) THEN
        CALL FlagError("Decomposition has been finished.",ERR,ERROR,*999)
      ELSE
        DECOMPOSITION%CALCULATE_CENTROIDS=CALCULATE_CENTROIDS_FLAG
      ENDIF
    ELSE
      CALL FlagError("Decomposition is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_CALCULATE_CENTROIDS_SET")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_CALCULATE_CENTROIDS_SET",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_CALCULATE_CENTROIDS_SET

  !
  !================================================================================================================================
  !

  !>Sets/changes whether lengths from centroid to face and centroid to neighbouring centroid should be calculated in the the decomposition. \see OPENCMISS::Iron::cmfe_DecompositionCalculateFVLengthsSet
  SUBROUTINE DECOMPOSITION_CALCULATE_CENTRE_LENGTHS_SET(DECOMPOSITION,CALCULATE_CENTRE_LENGTHS_FLAG,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION !<A pointer to the decomposition
    LOGICAL, INTENT(IN) :: CALCULATE_CENTRE_LENGTHS_FLAG !<The boolean flag to determine whether the CENTRE_LENGTHS should be calculated or not
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string

    ENTERS("DECOMPOSITION_CALCULATE_CENTRE_LENGTHS_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(DECOMPOSITION)) THEN
      IF(DECOMPOSITION%DECOMPOSITION_FINISHED) THEN
        CALL FlagError("Decomposition has been finished.",ERR,ERROR,*999)
      ELSE
        DECOMPOSITION%CALCULATE_CENTRE_LENGTHS=CALCULATE_CENTRE_LENGTHS_FLAG
      ENDIF
    ELSE
      CALL FlagError("Decomposition is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_CALCULATE_CENTRE_LENGTHS_SET")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_CALCULATE_CENTRE_LENGTHS_SET",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_CALCULATE_CENTRE_LENGTHS_SET

  !
  !================================================================================================================================
  !

  !>Finalises the domain decompositions for a given mesh. \todo Pass in a pointer to the decompositions.
  SUBROUTINE DECOMPOSITIONS_FINALISE(MESH,ERR,ERROR,*)

    !Argument variables
    TYPE(MESH_TYPE), POINTER :: MESH !<A pointer to the mesh to finalise the decomposition for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DECOMPOSITIONS_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(MESH)) THEN
      IF(ASSOCIATED(MESH%DECOMPOSITIONS)) THEN
        DO WHILE(MESH%DECOMPOSITIONS%NUMBER_OF_DECOMPOSITIONS>0)
          CALL DECOMPOSITION_DESTROY(MESH%DECOMPOSITIONS%DECOMPOSITIONS(1)%PTR,ERR,ERROR,*999)
        ENDDO !no_decomposition
       DEALLOCATE(MESH%DECOMPOSITIONS)
      ENDIF
    ELSE
      CALL FlagError("Mesh is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITIONS_FINALISE")
    RETURN
999 ERRORSEXITS("DECOMPOSITIONS_FINALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITIONS_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the domain decompositions for a given mesh.
  SUBROUTINE DECOMPOSITIONS_INITIALISE(MESH,ERR,ERROR,*)

    !Argument variables
    TYPE(MESH_TYPE), POINTER :: MESH !<A pointer to the mesh to initialise the decompositions for

    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DECOMPOSITIONS_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(MESH)) THEN
      IF(ASSOCIATED(MESH%DECOMPOSITIONS)) THEN
        CALL FlagError("Mesh already has decompositions associated.",ERR,ERROR,*999)
      ELSE
        ALLOCATE(MESH%DECOMPOSITIONS,STAT=ERR)
        IF(ERR/=0) CALL FlagError("Mesh decompositions could not be allocated.",ERR,ERROR,*999)
        MESH%DECOMPOSITIONS%NUMBER_OF_DECOMPOSITIONS=0
        MESH%DECOMPOSITIONS%MESH=>MESH
      ENDIF
    ELSE
      CALL FlagError("Mesh is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITIONS_INITIALISE")
    RETURN
999 ERRORSEXITS("DECOMPOSITIONS_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITIONS_INITIALISE

  !
  !================================================================================================================================
  !

  !>Finalises the domain for a given decomposition and deallocates all memory. \todo Pass in a pointer to the domain
  SUBROUTINE DOMAIN_FINALISE(DECOMPOSITION,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION !<A pointer to the decomposition to finalise the domain for.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: component_idx

    ENTERS("DOMAIN_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(DECOMPOSITION)) THEN
      IF(ASSOCIATED(DECOMPOSITION%MESH)) THEN
        IF(ASSOCIATED(DECOMPOSITION%DOMAIN)) THEN
          DO component_idx=1,SIZE(DECOMPOSITION%DOMAIN,1)
            IF(ALLOCATED(DECOMPOSITION%DOMAIN(component_idx)%PTR%NODE_DOMAIN))  &
              & DEALLOCATE(DECOMPOSITION%DOMAIN(component_idx)%PTR%NODE_DOMAIN)
            CALL DOMAIN_MAPPINGS_FINALISE(DECOMPOSITION%DOMAIN(component_idx)%PTR,ERR,ERROR,*999)
            CALL DOMAIN_TOPOLOGY_FINALISE(DECOMPOSITION%DOMAIN(component_idx)%PTR,ERR,ERROR,*999)
            DEALLOCATE(DECOMPOSITION%DOMAIN(component_idx)%PTR)
          ENDDO !component_idx
          DEALLOCATE(DECOMPOSITION%DOMAIN)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Decomposition is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_FINALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_FINALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DOMAIN_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the domain for a given decomposition.
  SUBROUTINE DOMAIN_INITIALISE(DECOMPOSITION,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION !<A pointer to the decomposition to initialise the domain for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: component_idx

    ENTERS("DOMAIN_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(DECOMPOSITION)) THEN
      IF(ASSOCIATED(DECOMPOSITION%MESH)) THEN
        IF(ASSOCIATED(DECOMPOSITION%DOMAIN)) THEN
          CALL FlagError("Decomposition already has a domain associated.",ERR,ERROR,*999)
        ELSE
          ALLOCATE(DECOMPOSITION%DOMAIN(DECOMPOSITION%numberOfComponents),STAT=ERR)
          IF(ERR/=0) CALL FlagError("Decomposition domain could not be allocated.",ERR,ERROR,*999)
          DO component_idx=1,DECOMPOSITION%numberOfComponents!Mesh component
            ALLOCATE(DECOMPOSITION%DOMAIN(component_idx)%PTR,STAT=ERR)
            IF(ERR/=0) CALL FlagError("Decomposition domain component could not be allocated.",ERR,ERROR,*999)
            DECOMPOSITION%DOMAIN(component_idx)%PTR%DECOMPOSITION=>DECOMPOSITION
            DECOMPOSITION%DOMAIN(component_idx)%PTR%MESH=>DECOMPOSITION%MESH
            DECOMPOSITION%DOMAIN(component_idx)%PTR%MESH_COMPONENT_NUMBER=component_idx
            DECOMPOSITION%DOMAIN(component_idx)%PTR%REGION=>DECOMPOSITION%region
            DECOMPOSITION%DOMAIN(component_idx)%PTR%NUMBER_OF_DIMENSIONS=DECOMPOSITION%numberOfDimensions
            !DECOMPOSITION%DOMAIN(component_idx)%PTR%NUMBER_OF_ELEMENTS=0
            !DECOMPOSITION%DOMAIN(component_idx)%PTR%NUMBER_OF_FACES=0
            !DECOMPOSITION%DOMAIN(component_idx)%PTR%NUMBER_OF_LINES=0
            !DECOMPOSITION%DOMAIN(component_idx)%PTR%NUMBER_OF_NODES=0
            !DECOMPOSITION%DOMAIN(component_idx)%PTR%NUMBER_OF_MESH_DOFS=0
            NULLIFY(DECOMPOSITION%DOMAIN(component_idx)%PTR%MAPPINGS)
            NULLIFY(DECOMPOSITION%DOMAIN(component_idx)%PTR%TOPOLOGY)
            CALL DOMAIN_MAPPINGS_INITIALISE(DECOMPOSITION%DOMAIN(component_idx)%PTR,ERR,ERROR,*999)
            CALL DOMAIN_TOPOLOGY_INITIALISE(DECOMPOSITION%DOMAIN(component_idx)%PTR,ERR,ERROR,*999)
          ENDDO !component_idx
        ENDIF
      ELSE
        CALL FlagError("Decomposition mesh is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Decomposition is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_INITIALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_INITIALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DOMAIN_INITIALISE

 !
  !================================================================================================================================
  !

  !>Finalises the dofs mapping in the given domain mappings. \todo Pass in the domain mappings dofs
  SUBROUTINE DOMAIN_MAPPINGS_DOFS_FINALISE(DOMAIN_MAPPINGS,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_MAPPINGS_TYPE), POINTER :: DOMAIN_MAPPINGS !<A pointer to the domain mappings to finalise the dofs for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_MAPPINGS_DOFS_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(DOMAIN_MAPPINGS)) THEN
      IF(ASSOCIATED(DOMAIN_MAPPINGS%DOFS)) THEN
        CALL DOMAIN_MAPPINGS_MAPPING_FINALISE(DOMAIN_MAPPINGS%DOFS,ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Domain mapping is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_MAPPINGS_DOFS_FINALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_MAPPINGS_DOFS_FINALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DOMAIN_MAPPINGS_DOFS_FINALISE

  !
  !================================================================================================================================
  !

  !>Intialises the dofs mapping in the given domain mapping.
  SUBROUTINE DOMAIN_MAPPINGS_DOFS_INITIALISE(DOMAIN_MAPPINGS,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_MAPPINGS_TYPE), POINTER :: DOMAIN_MAPPINGS !<A pointer to the domain mappings to initialise the dofs for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_MAPPINGS_DOFS_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(DOMAIN_MAPPINGS)) THEN
      IF(ASSOCIATED(DOMAIN_MAPPINGS%DOFS)) THEN
        CALL FlagError("Domain dofs mappings are already associated.",ERR,ERROR,*999)
      ELSE
        ALLOCATE(DOMAIN_MAPPINGS%DOFS,STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate domain mappings dofs.",ERR,ERROR,*999)
        CALL DOMAIN_MAPPINGS_MAPPING_INITIALISE(DOMAIN_MAPPINGS%DOFS,DOMAIN_MAPPINGS%DOMAIN%DECOMPOSITION%NUMBER_OF_DOMAINS, &
          & ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Domain mapping is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_MAPPINGS_DOFS_INITIALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_MAPPINGS_DOFS_INITIALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DOMAIN_MAPPINGS_DOFS_INITIALISE

  !
  !================================================================================================================================
  !

  !>Calculates the local/global element mappings for a domain decomposition.
  SUBROUTINE DOMAIN_MAPPINGS_ELEMENTS_CALCULATE(DOMAIN,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_TYPE), POINTER :: DOMAIN !<A pointer to the domain to calculate the element mappings for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR,no_adjacent_element,adjacent_element,domain_no,domain_idx,ne,nn,np,NUMBER_OF_DOMAINS, &
      & NUMBER_OF_ADJACENT_ELEMENTS,myComputationalNodeNumber,component_idx
    INTEGER(INTG), ALLOCATABLE :: ADJACENT_ELEMENTS(:),DOMAINS(:),LOCAL_ELEMENT_NUMBERS(:)
    TYPE(LIST_TYPE), POINTER :: ADJACENT_DOMAINS_LIST
    TYPE(LIST_PTR_TYPE), ALLOCATABLE :: ADJACENT_ELEMENTS_LIST(:)
    TYPE(BASIS_TYPE), POINTER :: BASIS
    TYPE(MESH_TYPE), POINTER :: MESH
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: ELEMENTS_MAPPING
    TYPE(VARYING_STRING) :: DUMMY_ERROR

    ENTERS("DOMAIN_MAPPINGS_ELEMENTS_CALCULATE",ERR,ERROR,*999)

    IF(ASSOCIATED(DOMAIN)) THEN
      IF(ASSOCIATED(DOMAIN%MAPPINGS)) THEN
        IF(ASSOCIATED(DOMAIN%MAPPINGS%ELEMENTS)) THEN
          ELEMENTS_MAPPING=>DOMAIN%MAPPINGS%ELEMENTS
          IF(ASSOCIATED(DOMAIN%DECOMPOSITION)) THEN
            DECOMPOSITION=>DOMAIN%DECOMPOSITION
            IF(ASSOCIATED(DOMAIN%MESH)) THEN
              MESH=>DOMAIN%MESH
              component_idx=DOMAIN%MESH_COMPONENT_NUMBER
              myComputationalNodeNumber=ComputationalEnvironment_NodeNumberGet(ERR,ERROR)
              IF(ERR/=0) GOTO 999

              !Calculate the local and global numbers and set up the mappings
              ALLOCATE(ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(MESH%NUMBER_OF_ELEMENTS),STAT=ERR)
              IF(ERR/=0) CALL FlagError("Could not allocate element mapping global to local map.",ERR,ERROR,*999)
              ELEMENTS_MAPPING%NUMBER_OF_GLOBAL=MESH%TOPOLOGY(component_idx)%PTR%ELEMENTS%NUMBER_OF_ELEMENTS
              !Loop over the global elements and calculate local numbers
              ALLOCATE(LOCAL_ELEMENT_NUMBERS(0:DECOMPOSITION%NUMBER_OF_DOMAINS-1),STAT=ERR)
              IF(ERR/=0) CALL FlagError("Could not allocate local element numbers.",ERR,ERROR,*999)
              LOCAL_ELEMENT_NUMBERS=0
              ALLOCATE(ADJACENT_ELEMENTS_LIST(0:DECOMPOSITION%NUMBER_OF_DOMAINS-1),STAT=ERR)
              IF(ERR/=0) CALL FlagError("Could not allocate adjacent elements list.",ERR,ERROR,*999)
              DO domain_idx=0,DECOMPOSITION%NUMBER_OF_DOMAINS-1
                NULLIFY(ADJACENT_ELEMENTS_LIST(domain_idx)%PTR)
                CALL LIST_CREATE_START(ADJACENT_ELEMENTS_LIST(domain_idx)%PTR,ERR,ERROR,*999)
                CALL LIST_DATA_TYPE_SET(ADJACENT_ELEMENTS_LIST(domain_idx)%PTR,LIST_INTG_TYPE,ERR,ERROR,*999)
                CALL LIST_INITIAL_SIZE_SET(ADJACENT_ELEMENTS_LIST(domain_idx)%PTR,MAX(INT(MESH%NUMBER_OF_ELEMENTS/2),1), &
                  & ERR,ERROR,*999)
                CALL LIST_CREATE_FINISH(ADJACENT_ELEMENTS_LIST(domain_idx)%PTR,ERR,ERROR,*999)
              ENDDO !domain_idx

              DO ne=1,MESH%NUMBER_OF_ELEMENTS
                !Calculate the local numbers
                domain_no=DECOMPOSITION%ELEMENT_DOMAIN(ne)
                LOCAL_ELEMENT_NUMBERS(domain_no)=LOCAL_ELEMENT_NUMBERS(domain_no)+1
                !Calculate the adjacent elements to the computational domains and the adjacent domain numbers themselves
                BASIS=>MESH%TOPOLOGY(component_idx)%PTR%ELEMENTS%ELEMENTS(ne)%BASIS
                NULLIFY(ADJACENT_DOMAINS_LIST)
                CALL LIST_CREATE_START(ADJACENT_DOMAINS_LIST,ERR,ERROR,*999)
                CALL LIST_DATA_TYPE_SET(ADJACENT_DOMAINS_LIST,LIST_INTG_TYPE,ERR,ERROR,*999)
                CALL LIST_INITIAL_SIZE_SET(ADJACENT_DOMAINS_LIST,DECOMPOSITION%NUMBER_OF_DOMAINS,ERR,ERROR,*999)
                CALL LIST_CREATE_FINISH(ADJACENT_DOMAINS_LIST,ERR,ERROR,*999)
                CALL LIST_ITEM_ADD(ADJACENT_DOMAINS_LIST,domain_no,ERR,ERROR,*999)
                DO nn=1,BASIS%NUMBER_OF_NODES
                  np=MESH%TOPOLOGY(component_idx)%PTR%ELEMENTS%ELEMENTS(ne)%MESH_ELEMENT_NODES(nn)
                  DO no_adjacent_element=1,MESH%TOPOLOGY(component_idx)%PTR%NODES%NODES(np)%numberOfSurroundingElements
                    adjacent_element=MESH%TOPOLOGY(component_idx)%PTR%NODES%NODES(np)%surroundingElements(no_adjacent_element)
                    IF(DECOMPOSITION%ELEMENT_DOMAIN(adjacent_element)/=domain_no) THEN
                      CALL LIST_ITEM_ADD(ADJACENT_ELEMENTS_LIST(domain_no)%PTR,adjacent_element,ERR,ERROR,*999)
                      CALL LIST_ITEM_ADD(ADJACENT_DOMAINS_LIST,DECOMPOSITION%ELEMENT_DOMAIN(adjacent_element),ERR,ERROR,*999)
                    ENDIF
                  ENDDO !no_adjacent_element
                ENDDO !nn
                CALL LIST_REMOVE_DUPLICATES(ADJACENT_DOMAINS_LIST,ERR,ERROR,*999)
                CALL LIST_DETACH_AND_DESTROY(ADJACENT_DOMAINS_LIST,NUMBER_OF_DOMAINS,DOMAINS,ERR,ERROR,*999)
                DEALLOCATE(DOMAINS)
                CALL DOMAIN_MAPPINGS_MAPPING_GLOBAL_INITIALISE(ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(ne),ERR,ERROR,*999)
                ALLOCATE(ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(ne)%LOCAL_NUMBER(NUMBER_OF_DOMAINS),STAT=ERR)
                IF(ERR/=0) CALL FlagError("Could not allocate element global to local map local number.",ERR,ERROR,*999)
                ALLOCATE(ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(ne)%DOMAIN_NUMBER(NUMBER_OF_DOMAINS),STAT=ERR)
                IF(ERR/=0) CALL FlagError("Could not allocate element global to local map domain number.",ERR,ERROR,*999)
                ALLOCATE(ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(ne)%LOCAL_TYPE(NUMBER_OF_DOMAINS),STAT=ERR)
                IF(ERR/=0) CALL FlagError("Could not allocate element global to local map local type.",ERR,ERROR,*999)
                ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(ne)%NUMBER_OF_DOMAINS=1
                ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(ne)%LOCAL_NUMBER(1)=LOCAL_ELEMENT_NUMBERS(domain_no)
                ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(ne)%DOMAIN_NUMBER(1)=DECOMPOSITION%ELEMENT_DOMAIN(ne)
                IF(NUMBER_OF_DOMAINS==1) THEN
                  !Element is an internal element
                  ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(ne)%LOCAL_TYPE(1)=DOMAIN_LOCAL_INTERNAL
                ELSE
                  !Element is on the boundary of computational domains
                  ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(ne)%LOCAL_TYPE(1)=DOMAIN_LOCAL_BOUNDARY
                ENDIF
              ENDDO !ne

              !Compute ghost element mappings
              DO domain_idx=0,DECOMPOSITION%NUMBER_OF_DOMAINS-1
                CALL LIST_REMOVE_DUPLICATES(ADJACENT_ELEMENTS_LIST(domain_idx)%PTR,ERR,ERROR,*999)
                CALL LIST_DETACH_AND_DESTROY(ADJACENT_ELEMENTS_LIST(domain_idx)%PTR,NUMBER_OF_ADJACENT_ELEMENTS, &
                  & ADJACENT_ELEMENTS,ERR,ERROR,*999)
                DO no_adjacent_element=1,NUMBER_OF_ADJACENT_ELEMENTS
                  adjacent_element=ADJACENT_ELEMENTS(no_adjacent_element)
                  LOCAL_ELEMENT_NUMBERS(domain_idx)=LOCAL_ELEMENT_NUMBERS(domain_idx)+1
                  ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(adjacent_element)%NUMBER_OF_DOMAINS= &
                    & ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(adjacent_element)%NUMBER_OF_DOMAINS+1
                  ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(adjacent_element)%LOCAL_NUMBER( &
                    & ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(adjacent_element)%NUMBER_OF_DOMAINS)=LOCAL_ELEMENT_NUMBERS(domain_idx)
                  ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(adjacent_element)%DOMAIN_NUMBER( &
                    & ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(adjacent_element)%NUMBER_OF_DOMAINS)=domain_idx
                  ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(adjacent_element)%LOCAL_TYPE( &
                    & ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(adjacent_element)%NUMBER_OF_DOMAINS)= &
                    & DOMAIN_LOCAL_GHOST
                ENDDO !no_adjacent_element
                IF(ALLOCATED(ADJACENT_ELEMENTS)) DEALLOCATE(ADJACENT_ELEMENTS)
              ENDDO !domain_idx

              DEALLOCATE(ADJACENT_ELEMENTS_LIST)
              DEALLOCATE(LOCAL_ELEMENT_NUMBERS)

              !Calculate element local to global maps from global to local map
              CALL DOMAIN_MAPPINGS_LOCAL_FROM_GLOBAL_CALCULATE(ELEMENTS_MAPPING,ERR,ERROR,*999)

            ELSE
              CALL FlagError("Domain mesh is not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Domain decomposition is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Domain mappings elements is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Domain mappings is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Domain is not associated.",ERR,ERROR,*998)
    ENDIF

    IF(DIAGNOSTICS1) THEN
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"Element mappings :",ERR,ERROR,*999)
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Global to local map :",ERR,ERROR,*999)
      DO ne=1,MESH%NUMBER_OF_ELEMENTS
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Global element = ",ne,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Number of domains  = ", &
          & ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(ne)%NUMBER_OF_DOMAINS,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(ne)% &
          & NUMBER_OF_DOMAINS,8,8,ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(ne)%LOCAL_NUMBER, &
          & '("      Local number :",8(X,I7))','(20X,8(X,I7))',ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(ne)% &
          & NUMBER_OF_DOMAINS,8,8,ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(ne)%DOMAIN_NUMBER, &
          & '("      Domain number:",8(X,I7))','(20X,8(X,I7))',ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(ne)% &
          & NUMBER_OF_DOMAINS,8,8,ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(ne)%LOCAL_TYPE, &
          & '("      Local type   :",8(X,I7))','(20X,8(X,I7))',ERR,ERROR,*999)
      ENDDO !ne
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Local to global map :",ERR,ERROR,*999)
      DO ne=1,ELEMENTS_MAPPING%TOTAL_NUMBER_OF_LOCAL
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Local element = ",ne,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Global element = ", &
          & ELEMENTS_MAPPING%LOCAL_TO_GLOBAL_MAP(ne),ERR,ERROR,*999)
      ENDDO !ne
      IF(DIAGNOSTICS2) THEN
        CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Internal elements :",ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Number of internal elements = ", &
          & ELEMENTS_MAPPING%NUMBER_OF_INTERNAL,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,ELEMENTS_MAPPING%NUMBER_OF_INTERNAL,8,8, &
          & ELEMENTS_MAPPING%DOMAIN_LIST(ELEMENTS_MAPPING%INTERNAL_START:ELEMENTS_MAPPING%INTERNAL_FINISH), &
          & '("    Internal elements:",8(X,I7))','(22X,8(X,I7))',ERR,ERROR,*999)
        CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Boundary elements :",ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Number of boundary elements = ", &
          & ELEMENTS_MAPPING%NUMBER_OF_BOUNDARY,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,ELEMENTS_MAPPING%NUMBER_OF_BOUNDARY,8,8, &
          & ELEMENTS_MAPPING%DOMAIN_LIST(ELEMENTS_MAPPING%BOUNDARY_START:ELEMENTS_MAPPING%BOUNDARY_FINISH), &
          & '("    Boundary elements:",8(X,I7))','(22X,8(X,I7))',ERR,ERROR,*999)
        CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Ghost elements :",ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Number of ghost elements = ", &
          & ELEMENTs_MAPPING%NUMBER_OF_GHOST,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,ELEMENTS_MAPPING%NUMBER_OF_GHOST,8,8, &
          & ELEMENTS_MAPPING%DOMAIN_LIST(ELEMENTS_MAPPING%GHOST_START:ELEMENTS_MAPPING%GHOST_FINISH), &
          & '("    Ghost elements   :",8(X,I7))','(22X,8(X,I7))',ERR,ERROR,*999)
      ENDIF
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Adjacent domains :",ERR,ERROR,*999)
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Number of adjacent domains = ", &
        & ELEMENTS_MAPPING%NUMBER_OF_ADJACENT_DOMAINS,ERR,ERROR,*999)
      CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,ELEMENTS_MAPPING%NUMBER_OF_DOMAINS+1,8,8, &
        & ELEMENTS_MAPPING%ADJACENT_DOMAINS_PTR,'("    Adjacent domains ptr  :",8(X,I7))','(27X,8(X,I7))',ERR,ERROR,*999)
      CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,ELEMENTS_MAPPING%ADJACENT_DOMAINS_PTR( &
        & ELEMENTS_MAPPING%NUMBER_OF_DOMAINS)-1,8,8,ELEMENTS_MAPPING%ADJACENT_DOMAINS_LIST, &
        '("    Adjacent domains list :",8(X,I7))','(27X,8(X,I7))',ERR,ERROR,*999)
      DO domain_idx=1,ELEMENTS_MAPPING%NUMBER_OF_ADJACENT_DOMAINS
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Adjacent domain idx : ",domain_idx,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Domain number = ", &
          & ELEMENTS_MAPPING%ADJACENT_DOMAINS(domain_idx)%DOMAIN_NUMBER,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Number of send ghosts    = ", &
          & ELEMENTS_MAPPING%ADJACENT_DOMAINS(domain_idx)%NUMBER_OF_SEND_GHOSTS,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,ELEMENTS_MAPPING%ADJACENT_DOMAINS(domain_idx)% &
          & NUMBER_OF_SEND_GHOSTS,6,6,ELEMENTS_MAPPING%ADJACENT_DOMAINS(domain_idx)%LOCAL_GHOST_SEND_INDICES, &
          & '("      Local send ghost indicies       :",6(X,I7))','(39X,6(X,I7))',ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Number of recieve ghosts = ", &
          & ELEMENTS_MAPPING%ADJACENT_DOMAINS(domain_idx)%NUMBER_OF_RECEIVE_GHOSTS,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,ELEMENTS_MAPPING%ADJACENT_DOMAINS(domain_idx)% &
          & NUMBER_OF_RECEIVE_GHOSTS,6,6,ELEMENTS_MAPPING%ADJACENT_DOMAINS(domain_idx)%LOCAL_GHOST_RECEIVE_INDICES, &
          & '("      Local receive ghost indicies    :",6(X,I7))','(39X,6(X,I7))',ERR,ERROR,*999)
      ENDDO !domain_idx
    ENDIF

    EXITS("DOMAIN_MAPPINGS_ELEMENTS_CALCULATE")
    RETURN
999 IF(ALLOCATED(DOMAINS)) DEALLOCATE(DOMAINS)
    IF(ALLOCATED(ADJACENT_ELEMENTS)) DEALLOCATE(ADJACENT_ELEMENTS)
    IF(ASSOCIATED(DOMAIN%MAPPINGS%ELEMENTS)) CALL DOMAIN_MAPPINGS_ELEMENTS_FINALISE(DOMAIN%MAPPINGS,DUMMY_ERR,DUMMY_ERROR,*998)
998 ERRORSEXITS("DOMAIN_MAPPINGS_ELEMENTS_CALCULATE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DOMAIN_MAPPINGS_ELEMENTS_CALCULATE

  !
  !================================================================================================================================
  !

  !>Finalises the mappings in the given domain. \todo pass in the domain mappings
  SUBROUTINE DOMAIN_MAPPINGS_FINALISE(DOMAIN,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_TYPE), POINTER :: DOMAIN !<A pointer to the domain to finalise the mappings for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_MAPPINGS_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(DOMAIN)) THEN
      CALL DOMAIN_MAPPINGS_ELEMENTS_FINALISE(DOMAIN%MAPPINGS,ERR,ERROR,*999)
      CALL DOMAIN_MAPPINGS_NODES_FINALISE(DOMAIN%MAPPINGS,ERR,ERROR,*999)
      CALL DOMAIN_MAPPINGS_DOFS_FINALISE(DOMAIN%MAPPINGS,ERR,ERROR,*999)
      IF(DOMAIN%DECOMPOSITION%CALCULATE_LINES) THEN
        CALL DomainMappings_LinesFinalise(DOMAIN%MAPPINGS,ERR,ERROR,*999)
      ENDIF
      IF(DOMAIN%DECOMPOSITION%CALCULATE_FACES) THEN
        CALL DomainMappings_FacesFinalise(DOMAIN%MAPPINGS,ERR,ERROR,*999)
      ENDIF
      DEALLOCATE(DOMAIN%MAPPINGS)
    ELSE
      CALL FlagError("Domain is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_MAPPINGS_FINALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_MAPPINGS_FINALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DOMAIN_MAPPINGS_FINALISE

  !
  !================================================================================================================================
  !

  !>Finalises the element mapping in the given domain mapping. \todo pass in the domain mappings elements
  SUBROUTINE DOMAIN_MAPPINGS_ELEMENTS_FINALISE(DOMAIN_MAPPINGS,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_MAPPINGS_TYPE), POINTER :: DOMAIN_MAPPINGS !<A pointer to the domain mappings to finalise the elements for.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_MAPPINGS_ELEMENTS_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(DOMAIN_MAPPINGS)) THEN
      IF(ASSOCIATED(DOMAIN_MAPPINGS%ELEMENTS)) THEN
        CALL DOMAIN_MAPPINGS_MAPPING_FINALISE(DOMAIN_MAPPINGS%ELEMENTS,ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Domain mapping is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_MAPPINGS_ELEMENTS_FINALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_MAPPINGS_ELEMENTS_FINALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DOMAIN_MAPPINGS_ELEMENTS_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the element mapping in the given domain mapping.
  SUBROUTINE DOMAIN_MAPPINGS_ELEMENTS_INITIALISE(DOMAIN_MAPPINGS,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_MAPPINGS_TYPE), POINTER :: DOMAIN_MAPPINGS !<A pointer to the domain mappings to initialise the elements for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_MAPPINGS_ELEMENTS_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(DOMAIN_MAPPINGS)) THEN
      IF(ASSOCIATED(DOMAIN_MAPPINGS%ELEMENTS)) THEN
        CALL FlagError("Domain elements mappings are already associated.",ERR,ERROR,*999)
      ELSE
        ALLOCATE(DOMAIN_MAPPINGS%ELEMENTS,STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate domain mappings elements.",ERR,ERROR,*999)
        CALL DOMAIN_MAPPINGS_MAPPING_INITIALISE(DOMAIN_MAPPINGS%ELEMENTS,DOMAIN_MAPPINGS%DOMAIN%DECOMPOSITION%NUMBER_OF_DOMAINS, &
          & ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Domain mapping is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_MAPPINGS_ELEMENTS_INITIALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_MAPPINGS_ELEMENTS_INITIALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DOMAIN_MAPPINGS_ELEMENTS_INITIALISE

  !
  !================================================================================================================================
  !

  !>Initialises the mappings for a domain decomposition. \todo finalise on error.
  SUBROUTINE DOMAIN_MAPPINGS_INITIALISE(DOMAIN,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_TYPE), POINTER :: DOMAIN !<A pointer to the domain to initialise the mappings for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_MAPPINGS_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(DOMAIN)) THEN
      IF(ASSOCIATED(DOMAIN%MAPPINGS)) THEN
        CALL FlagError("Domain already has mappings associated.",ERR,ERROR,*999)
      ELSE
        ALLOCATE(DOMAIN%MAPPINGS,STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate domain mappings.",ERR,ERROR,*999)
        DOMAIN%MAPPINGS%DOMAIN=>DOMAIN
        NULLIFY(DOMAIN%MAPPINGS%ELEMENTS)
        NULLIFY(DOMAIN%MAPPINGS%NODES)
        NULLIFY(DOMAIN%MAPPINGS%DOFS)
        NULLIFY(DOMAIN%MAPPINGS%FACES)
        NULLIFY(DOMAIN%MAPPINGS%LINES)
        !Calculate the node and element mappings
        CALL DOMAIN_MAPPINGS_ELEMENTS_INITIALISE(DOMAIN%MAPPINGS,ERR,ERROR,*999)
        CALL DOMAIN_MAPPINGS_NODES_INITIALISE(DOMAIN%MAPPINGS,ERR,ERROR,*999)
        CALL DOMAIN_MAPPINGS_DOFS_INITIALISE(DOMAIN%MAPPINGS,ERR,ERROR,*999)
        CALL DOMAIN_MAPPINGS_ELEMENTS_CALCULATE(DOMAIN,ERR,ERROR,*999)
        CALL DOMAIN_MAPPINGS_NODES_DOFS_CALCULATE(DOMAIN,ERR,ERROR,*999)

        !Map the local face numbers to the global numbers
        SELECT CASE(DOMAIN%NUMBER_OF_DIMENSIONS)
        CASE(1)
          IF(DOMAIN%DECOMPOSITION%CALCULATE_LINES) THEN
            CALL DomainMappings_LinesInitialise(DOMAIN%MAPPINGS,ERR,ERROR,*999)
            CALL DomainMappings_1DLinesCalculate(DOMAIN,ERR,ERROR,*999)
          ENDIF
        CASE(2)
          IF(DOMAIN%DECOMPOSITION%CALCULATE_LINES) THEN
            CALL DomainMappings_LinesInitialise(DOMAIN%MAPPINGS,ERR,ERROR,*999)
            CALL DomainMappings_2DLinesCalculate(DOMAIN,ERR,ERROR,*999)
          ENDIF
          !else do nothing
        CASE(3)
          IF(DOMAIN%DECOMPOSITION%CALCULATE_LINES) THEN
            !FIXTHIS
            CALL FlagError("3D is not yet implemented for line mappings",ERR,ERROR,*999)
            !FIXTHIS The below subroutine needs to be modified for 3D models and DECOMPOSITION_TOPOLOGY_LINES_CALCULATE needs to be updated
            !Or a DomainMappings_3DLinesInitialise and DomainMappings_3DLinesCalculate should be created to create the lines in 3D models
            CALL DomainMappings_LinesInitialise(DOMAIN%MAPPINGS,ERR,ERROR,*999)
            !FIXTHIS change this to 3D lines calculate and create the subroutine
            CALL DomainMappings_2DLinesCalculate(DOMAIN,ERR,ERROR,*999)
          ENDIF
          !else do nothing
          IF(DOMAIN%DECOMPOSITION%CALCULATE_FACES) THEN
            !FIXTHIS
            ! CALL FlagError("3D is not yet implemented for face mappings",ERR,ERROR,*999)
            !FIXTHIS The below subroutine needs to be tested for 3D models and DECOMPOSITION_TOPOLOGY_FACES_CALCULATE needs to be updated
            CALL DomainMappings_FacesInitialise(DOMAIN%MAPPINGS,ERR,ERROR,*999)
            CALL DomainMappings_FacesCalculate(DOMAIN,ERR,ERROR,*999)
          ENDIF
          !else do nothing
        END SELECT
      ENDIF
    ELSE
      CALL FlagError("Domain is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_MAPPINGS_INITIALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_MAPPINGS_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DOMAIN_MAPPINGS_INITIALISE

  !
  !================================================================================================================================
  !

  !>Initialises the face mapping in the given domain mapping. \todo finalise on error
  SUBROUTINE DomainMappings_FacesInitialise(Domain_Mappings,err,error,*)

    !Argument variables
    TYPE(DOMAIN_MAPPINGS_TYPE), POINTER :: Domain_Mappings !<A pointer to the domain mappings to initialise the faces for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables

    ENTERS("DomainMappings_FacesInitialise",err,error,*999)

    IF(.NOT.ASSOCIATED(Domain_Mappings)) CALL FlagError("Domain mapping is not associated.",err,error,*999)
    IF(ASSOCIATED(Domain_Mappings%FACES)) THEN
      CALL FlagError("Domain faces mappings are already associated.",err,error,*999)
    ELSE
      ALLOCATE(Domain_Mappings%FACES,STAT=err)
      IF(err/=0) CALL FlagError("Could not allocate domain mappings faces.",err,error,*999)
      CALL DOMAIN_MAPPINGS_MAPPING_INITIALISE(Domain_Mappings%FACES,DOMAIN_MAPPINGS%DOMAIN%DECOMPOSITION%NUMBER_OF_DOMAINS, &
        & err,error,*999)
    ENDIF

    EXITS("DomainMappings_FacesInitialise")
    RETURN
999 ERRORSEXITS("DomainMappings_FacesInitialise",err,error)
    RETURN 1

  END SUBROUTINE DomainMappings_FacesInitialise

  !
  !================================================================================================================================
  !

  !>Finalises the face mapping in the given domain mappings. \todo pass in the faces mapping
  SUBROUTINE DomainMappings_FacesFinalise(Domain_Mappings,err,error,*)


    !Argument variables
    TYPE(DOMAIN_MAPPINGS_TYPE), POINTER :: Domain_Mappings !<A pointer to the domain mappings to initialise the faces for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables

    ENTERS("DomainMappings_FacesFinalise",err,error,*999)

    IF(.NOT.ASSOCIATED(Domain_Mappings)) CALL FlagError("Domain mapping is not associated.",err,error,*999)
    IF(.NOT.ASSOCIATED(Domain_Mappings%FACES)) CALL FlagError("Domain mapping faces is not associated.",err,error,*999)
      CALL DOMAIN_MAPPINGS_MAPPING_FINALISE(Domain_Mappings%FACES,err,error,*999)

    EXITS("DomainMappings_FacesFinalise")
    RETURN
999 ERRORSEXITS("DomainMappings_FacesFinalise",err,error)
    RETURN 1

  END SUBROUTINE DomainMappings_FacesFinalise


  !
  !================================================================================================================================
  !

  !>Initialises the line mapping in the given domain mapping. \todo finalise on error
  SUBROUTINE DomainMappings_LinesInitialise(domainMappings,err,error,*)

    !Argument variables
    TYPE(DOMAIN_MAPPINGS_TYPE), POINTER :: domainMappings !<A pointer to the domain mappings to initialise the lines for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables

    ENTERS("DomainMappings_LinesInitialise",err,error,*999)

    IF(.NOT.ASSOCIATED(domainMappings)) CALL FlagError("Domain mapping is not associated.",err,error,*999)
    IF(ASSOCIATED(domainMappings%lines)) THEN
      CALL FlagError("Domain lines mappings are already associated.",err,error,*999)
    ELSE
      ALLOCATE(domainMappings%lines,STAT=err)
      IF(err/=0) CALL FlagError("Could not allocate domain mappings lines.",err,error,*999)
      CALL DOMAIN_MAPPINGS_MAPPING_INITIALISE(domainMappings%lines,domainMappings%DOMAIN%DECOMPOSITION%NUMBER_OF_DOMAINS, &
        & err,error,*999)
    ENDIF

    EXITS("DomainMappings_LinesInitialise")
    RETURN
999 ERRORSEXITS("DomainMappings_LinesInitialise",err,error)
    RETURN 1

  END SUBROUTINE DomainMappings_LinesInitialise

  !
  !================================================================================================================================
  !

  !>Finalises the line mapping in the given domain mappings. \todo pass in the lines mapping
  SUBROUTINE DomainMappings_LinesFinalise(domainMappings,err,error,*)


    !Argument variables
    TYPE(DOMAIN_MAPPINGS_TYPE), POINTER :: domainMappings !<A pointer to the domain mappings to initialise the lines for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables

    ENTERS("DomainMappings_LinesFinalise",err,error,*999)

    IF(.NOT.ASSOCIATED(domainMappings)) CALL FlagError("Domain mapping is not associated.",err,error,*999)
    IF(.NOT.ASSOCIATED(domainMappings%lines)) CALL FlagError("Domain mapping lines is not associated.",err,error,*999)
      CALL DOMAIN_MAPPINGS_MAPPING_FINALISE(domainMappings%lines,err,error,*999)

    EXITS("DomainMappings_LinesFinalise")
    RETURN
999 ERRORSEXITS("DomainMappings_LinesFinalise",err,error)
    RETURN 1

  END SUBROUTINE DomainMappings_LinesFinalise


  !
  !================================================================================================================================
  !

  !>Calculates the local/global face mappings for a domain decomposition.
  SUBROUTINE DomainMappings_FacesCalculate(domain,err,error,*)

    !Argument variables
    TYPE(DOMAIN_TYPE), POINTER :: domain !<A pointer to the domain to calculate the Face dofs for.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: myComputationalNodeNumber,numberComputationalNodes,componentIdx,numberBoundaryAndBoundaryPlaneFaces, &
      & faceGlobalNo, faceCount, elementGlobalNo, elementLocalNo, startNic, xicIdx, elementIdx, xicIdx2, &
      & adjacentElementIdx, adjacentElementGlobalNo, adjacentElementLocalNo, I, J, adjacentElementGlobalNo2, &
      & arrayIndex, adjacentDomainIdx, domainNo, numberDomains, adjacentDomain, numberLocalAndAdjacentDomains, &
      & numberNonBoundaryPlaneAndLocalFaces(2), numberLocalFaces, numberAdjacentDomains, MPI_IERROR, numberSharedFaces,  &
      & numberFacesWithThatSetOfDomains, sharedFaceIdx2, boundaryAndBoundaryPlaneFaceIdx2, domainToAssignFacesToIdx, sharedFaceIdx,&
      & domainToAssignFacesTo, adjacentDomainIdx2, numberLocalFacesOnRank, numberNonBoundaryFacesOnRank, &
      & numberSharedFacesOnRank, numberInCurrentSetToClaim, ghostFaceIdx, ghostFaceGlobalNo, ghostDomain, &
      & domainIdx, domainNo2, maximumNumberToSend, numberToSend, numberOfFacesToReceive, internalFacesIdx, &
      & boundaryFacesIdx, localFaceNo, domainListInternalIdx, domainListBoundaryIdx, internalFaceGlobalNo, boundaryFaceGlobalNo, &
      & domainListGhostIdx, dummyErr, numberBoundaryPlaneFaces, domainNo3, &
      & boundaryAndBoundaryPlaneFaceIdx, basisLocalFaceIdx2, &
      & extraAdjacentDomain, numberExtraAdjacentDomains,nodeIdx, meshNodeNo, surroundingElemIdx, basisLocalFaceIdx
    !
    INTEGER(INTG), ALLOCATABLE :: internalFaces(:), integerArray(:), boundaryAndBoundaryPlaneFaces(:), sendRequestHandle(:), &
      & numberNonBoundaryPlaneAndLocalFacesOnRank(:,:), receiveRequestHandle(:), boundaryAndBoundaryPlaneFacesDomain(:), &
      & numberFacesInDomain(:),adjacentDomains(:), localAndAdjacentDomains(:), boundaryFaces(:), &
      & sendRequestHandle0(:), sendRequestHandle1(:), ghostFacesDomains(:,:), sendBuffer(:,:), numberToSendToDomain(:), &
      & receiveBuffer(:), faceOnBoundaryPlane(:), integerArray2D(:,:), extraAdjacentDomains(:), &
      & tempArray(:)
    TYPE(MESH_TYPE), POINTER :: mesh
    TYPE(MeshComponentTopologyType), POINTER :: topology
    TYPE(DECOMPOSITION_TYPE), POINTER :: decomposition
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: elementsMapping
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: facesMapping
    TYPE(LIST_TYPE), POINTER :: internalFacesList, boundaryAndBoundaryPlaneFacesList, adjacentDomainsList, &
      & localAndAdjacentDomainsList, boundaryFacesList, ghostFacesDomainsList,extraAdjacentDomainsList
    TYPE(LIST_PTR_TYPE), ALLOCATABLE :: domainsOfFaceList(:), sharedFacesList(:), sendBufferList(:), localGhostSendIndices(:), &
       & localGhostReceiveIndices(:), domainsOfBoundaryPlaneFaceList(:)
    REAL(DP) :: numberFaces, optimalNumberFacesPerDomain, totalNumberFaces, portionToDistribute, numberFacesAboveOptimum
    LOGICAL :: onOtherDomain,adacentDomainEntryFound, found
    TYPE(VARYING_STRING) :: dummyError, localError

    ENTERS("DomainMappings_FacesCalculate",err,error,*999)


    !FIXTHIS shouldn't be indented, we want something like this... IF(.NOT.ASSOCIATED(domain)) CALL FlagError("domain is not associated.",err,error,*999)
    !Also fix typecase on subroutine calls. And but allocate parts in DomainMappings_FacesInitialise subroutine
    IF(.NOT.ASSOCIATED(domain)) CALL FlagError("domain is not associated.",err,error,*999)
    IF(.NOT.ASSOCIATED(domain%MAPPINGS)) CALL FlagError("domain%MAPPINGS is not associated.",err,error,*999)
    facesMapping=>domain%MAPPINGS%FACES

    IF(.NOT.ASSOCIATED(domain%MAPPINGS%ELEMENTS)) CALL FlagError("domain%MAPPINGS%ELEMENTS is not associated.",err,error,*999)
    elementsMapping=>domain%MAPPINGS%ELEMENTS
    IF(.NOT.ASSOCIATED(domain%decomposition)) CALL FlagError("domain%decomposition is not associated.",err,error,*999)
    decomposition=>domain%decomposition
    IF(.NOT.ASSOCIATED(domain%mesh)) CALL FlagError("domain%mesh is not associated.",err,error,*999)
    mesh=>domain%mesh
    componentIdx=domain%MESH_COMPONENT_NUMBER
    topology=>mesh%topology(componentIdx)%PTR

    numberComputationalNodes=ComputationalEnvironment_NumberOfNodesGet(err,error)
    IF(err/=0) GOTO 999
    myComputationalNodeNumber=ComputationalEnvironment_NodeNumberGet(err,error)
    IF(err/=0) GOTO 999

    IF(DIAGNOSTICS1) THEN
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,&
        & "  numberComputationalNodes: ",numberComputationalNodes,err,error,*999)

    ENDIF


    ! create list for internal Faces
    NULLIFY(internalFacesList)
    CALL LIST_CREATE_START(internalFacesList,err,error,*999)
    CALL LIST_DATA_TYPE_SET(internalFacesList,LIST_INTG_TYPE,err,error,*999)
    CALL LIST_INITIAL_SIZE_SET(internalFacesList,elementsMapping%NUMBER_OF_LOCAL*2,err,error,*999)
    CALL LIST_CREATE_FINISH(internalFacesList,err,error,*999)


    !determine start Nic for basis directions, i.e quads have (-3,-2,-1,1,2,3), tets have (1,2,3,4)
    SELECT CASE(topology%ELEMENTS%ELEMENTS(1)%BASIS%TYPE)!Assumes all elements have the same basis
    CASE(BASIS_SIMPLEX_TYPE)
      startNic=1
    CASE(BASIS_LAGRANGE_HERMITE_TP_TYPE)
      startNic=-topology%ELEMENTS%ELEMENTS(1)%BASIS%NUMBER_OF_XI_COORDINATES
    CASE DEFAULT
      !do nothing
    END SELECT


!>>.............. Topology equations should be in its own subroutine eventually



    CALL DomainTopology_AssignGlobalFacesInitialise(domain,err,error,*999)
    !could seperate the following into seperate subroutines
    !CALL DomainTopology_AssignGlobalFacesAndSurroundingElements(topology,err,error,*999)
    !CALL DomainTopology_AssignGlobalFaces(topology,err,error,*999)
    !Assign global numbers to each face
    faceCount=0

    DO elementGlobalNo = 1,topology%ELEMENTS%NUMBER_OF_ELEMENTS
      DO basisLocalFaceIdx = 1, topology%ELEMENTS%ELEMENTS(elementGlobalNo)%BASIS%NUMBER_OF_LOCAL_FACES
        xicIdx = topology%ELEMENTS%ELEMENTS(elementGlobalNo)%BASIS%localFaceXiNormal(basisLocalFaceIdx)
      ! DO xicIdx = startNic,topology%ELEMENTS%ELEMENTS(elementGlobalNo)%BASIS%NUMBER_OF_XI_COORDINATES
      !   IF(xicIdx ==0) CYCLE

        IF(topology%ELEMENTS%ELEMENTS(elementGlobalNo)%ADJACENT_ELEMENTS(xicIdx)%NUMBER_OF_ADJACENT_ELEMENTS==1) THEN
          adjacentElementGlobalNo=topology%ELEMENTS%ELEMENTS(elementGlobalNo)%ADJACENT_ELEMENTS(xicIdx)% &
            & ADJACENT_ELEMENTS(1)
          IF(adjacentElementGlobalNo>elementGlobalNo) THEN
            faceCount=faceCount+1
            topology%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_FACES(xicIdx)=faceCount

          ELSE
            DO basisLocalFaceIdx2 = 1, topology%ELEMENTS%ELEMENTS(adjacentElementGlobalNo)%BASIS%NUMBER_OF_LOCAL_FACES
              xicIdx2 = topology%ELEMENTS%ELEMENTS(adjacentElementGlobalNo)%BASIS%localFaceXiNormal(basisLocalFaceIdx2)

              IF(topology%ELEMENTS%ELEMENTS(adjacentElementGlobalNo)%ADJACENT_ELEMENTS(xicIdx2)% &
                & NUMBER_OF_ADJACENT_ELEMENTS==0) CYCLE

              ! IF (DIAGNOSTICS1) THEN
              !   CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,&
              !     & "xicIdx2",xicIdx2,err,error,*999)
              !   CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,&
              !     & "number internal faces: ",facesMapping%NUMBER_OF_INTERNAL,err,error,*999)
              ! ENDIF



              IF(topology%ELEMENTS%ELEMENTS(adjacentElementGlobalNo)%ADJACENT_ELEMENTS(xicIdx2)% &
                & ADJACENT_ELEMENTS(1)==elementGlobalNo) THEN
                topology%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_FACES(xicIdx)= &
                  & topology%ELEMENTS%ELEMENTS(adjacentElementGlobalNo)%GLOBAL_ELEMENT_FACES(xicIdx2)

              ENDIF
            ENDDO
          ENDIF

        ELSE
          faceCount=faceCount+1
          topology%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_FACES(xicIdx)=faceCount
        ENDIF
      ENDDO ! basisLocalFaceIdx
    ENDDO ! elementGlobalNo

    !FIXTHIS This dosn't neccesarily need to be using a type, could just use allocatable local arrays
    ALLOCATE(topology%faces)
    topology%faces%numberOfFaces=faceCount
    ALLOCATE(topology%faces%faces(faceCount))


    !Iterate through the elements to allocate surrounding elements This should be done in an initialise subroutine
    DO faceGlobalNo = 1,topology%faces%numberOfFaces

      ALLOCATE(topology%faces%faces(faceGlobalNo)%surroundingElements(2))
      topology%faces%faces(faceGlobalNo)%surroundingElements=-1
      topology%faces%faces(faceGlobalNo)%globalNumber=faceGlobalNo
      topology%faces%faces(faceGlobalNo)%numberOfSurroundingElements=0

    ENDDO


    !Iterate through the elements to assign them as neighbouring elements of the faces
    DO elementGlobalNo = 1,topology%ELEMENTS%NUMBER_OF_ELEMENTS
      !Iterate through the faces of this element
      DO basisLocalFaceIdx = 1, topology%ELEMENTS%ELEMENTS(elementGlobalNo)%BASIS%NUMBER_OF_LOCAL_FACES
        xicIdx = topology%ELEMENTS%ELEMENTS(elementGlobalNo)%BASIS%localFaceXiNormal(basisLocalFaceIdx)

        faceGlobalNo=topology%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_FACES(xicIdx)



        IF(topology%faces%faces(faceGlobalNo)%surroundingElements(1)==-1) THEN
          topology%faces%faces(faceGlobalNo)%surroundingElements(1)=elementGlobalNo
        ELSE
          topology%faces%faces(faceGlobalNo)%surroundingElements(2)=elementGlobalNo
        ENDIF
        topology%faces%faces(faceGlobalNo)%numberOfSurroundingElements=topology%faces%faces(faceGlobalNo)% &
          & numberOfSurroundingElements+1
      ENDDO ! basisLocalFaceIdx
    ENDDO ! elementGlobalNo

    DO faceGlobalNo = 1,topology%faces%numberOfFaces

      IF(topology%faces%faces(faceGlobalNo)%numberOfSurroundingElements==1) THEN
        !The face is an external face
        topology%faces%faces(faceGlobalNo)%externalFace=.TRUE.
      ELSEIF(topology%faces%faces(faceGlobalNo)%numberOfSurroundingElements==2) THEN
        topology%faces%faces(faceGlobalNo)%externalFace=.FALSE.
      ELSE
        localError="A Face can only have 1 or 2 surrounding elements, not "//TRIM(NumberToVString( &
          & topology%faces%faces(faceGlobalNo)%numberOfSurroundingElements,"*",err,error))
        CALL FlagError(localError,err,error,*999)
      ENDIF

    ENDDO
!<<.............. Topology equations should be in their own subroutine eventually

    !allocate temporary array for the global numbers of the boundary elements
    ALLOCATE(tempArray(elementsMapping%NUMBER_OF_BOUNDARY))
    tempArray=elementsMapping%LOCAL_TO_GLOBAL_MAP(elementsMapping%DOMAIN_LIST(elementsMapping%BOUNDARY_START: &
      & elementsMapping%BOUNDARY_FINISH))

    ! determine interior Faces
    ! loop over interior elements
    DO elementIdx = elementsMapping%INTERNAL_START,elementsMapping%INTERNAL_FINISH
      elementLocalNo = elementsMapping%DOMAIN_LIST(elementIdx)
      elementGlobalNo = elementsMapping%LOCAL_TO_GLOBAL_MAP(elementLocalNo)

      ! loop over Faces of element
      DO basisLocalFaceIdx = 1, topology%ELEMENTS%ELEMENTS(elementGlobalNo)%BASIS%NUMBER_OF_LOCAL_FACES
        xicIdx = topology%ELEMENTS%ELEMENTS(elementGlobalNo)%BASIS%localFaceXiNormal(basisLocalFaceIdx)

        faceGlobalNo=topology%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_FACES(xicIdx)


        onOtherDomain = .FALSE.


        ! determine if any of this faces adjacent elements are boundary elements, that is the case if it is a boundary face.
        DO adjacentElementIdx=1,topology%faces%faces(faceGlobalNo)%numberOfSurroundingElements
          adjacentElementGlobalNo=topology%faces%faces(faceGlobalNo)%surroundingElements(adjacentElementIdx)

          !tempArray holds the global element numbers of the boundary elements of this rank
          IF (SORTED_ARRAY_CONTAINS_ELEMENT(tempArray,adjacentElementGlobalNo,err,error)) THEN

            onOtherDomain = .TRUE.
            EXIT
          ENDIF

        ENDDO

        !If face is not a boundary face it is an interal face.
        IF (.NOT. onOtherDomain) THEN
          ! add Face to internal Face list
          CALL LIST_ITEM_ADD(internalFacesList, faceGlobalNo,err,error,*999)
        ENDIF
      ENDDO
    ENDDO

    IF(ALLOCATED(tempArray)) DEALLOCATE(tempArray)


    ! sort list by global face number store number of internal faces in faceMapping
    CALL LIST_REMOVE_DUPLICATES(internalFacesList,err,error,*999)
    CALL LIST_DETACH_AND_DESTROY(internalFacesList,facesMapping%NUMBER_OF_INTERNAL,&
    & integerArray,err,error,*999)
    ALLOCATE(internalFaces(facesMapping%NUMBER_OF_INTERNAL))
    internalFaces=integerArray(1:facesMapping%NUMBER_OF_INTERNAL)

    IF(ALLOCATED(integerArray)) DEALLOCATE(integerArray)



    IF (DIAGNOSTICS1) THEN
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,&
        & "number internal faces: ",facesMapping%NUMBER_OF_INTERNAL,err,error,*999)
      DO I=1,facesMapping%NUMBER_OF_INTERNAL
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  global no. ", &
          & internalFaces(I),err,error,*999)
      ENDDO
    ENDIF


    ! create list for boundary and boundary plane faces (global face numbers)
    NULLIFY(boundaryAndBoundaryPlaneFacesList)
    CALL LIST_CREATE_START(boundaryAndBoundaryPlaneFacesList,err,error,*999)
    CALL LIST_DATA_TYPE_SET(boundaryAndBoundaryPlaneFacesList,LIST_INTG_TYPE,err,error,*999)
    CALL LIST_INITIAL_SIZE_SET(boundaryAndBoundaryPlaneFacesList,elementsMapping%NUMBER_OF_LOCAL,err,error,*999)
    CALL LIST_CREATE_FINISH(boundaryAndBoundaryPlaneFacesList,err,error,*999)

    ! loop over boundary elements
    DO elementIdx = elementsMapping%BOUNDARY_START,elementsMapping%BOUNDARY_FINISH
      elementLocalNo = elementsMapping%DOMAIN_LIST(elementIdx)
      elementGlobalNo = elementsMapping%LOCAL_TO_GLOBAL_MAP(elementLocalNo)

      ! loop over Faces of element
      DO basisLocalFaceIdx = 1, topology%ELEMENTS%ELEMENTS(elementGlobalNo)%BASIS%NUMBER_OF_LOCAL_FACES
        xicIdx = topology%ELEMENTS%ELEMENTS(elementGlobalNo)%BASIS%localFaceXiNormal(basisLocalFaceIdx)
        faceGlobalNo=topology%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_FACES(xicIdx)

        ! if global face is not contained in internal faces list
        IF (.NOT. SORTED_ARRAY_CONTAINS_ELEMENT(internalFaces,faceGlobalNo,err,error)) THEN

          ! Add face to boundary faces list (Important! This is called boundaryAndBoundaryPlaneFaces because it contains all the boundary &
          ! & boundary plane faces, even though some of the boundary plane faces will be ghost faces).
          IF(elementIdx<=elementsMapping%BOUNDARY_FINISH) THEN
            CALL LIST_ITEM_ADD(boundaryAndBoundaryPlaneFacesList,faceGlobalNo,err,error,*999)
          ENDIF
        ELSE
          localError="global face number  "//TRIM(NumberToVString(faceGlobalNo,"*",err,error))// &
          & " is contained in internal faces when it should be a boundary face."
          CALL FlagError(localError,err,error,*999)
        ENDIF
      ENDDO
    ENDDO

    ! Sort list by global face number and remove duplicates
    CALL LIST_REMOVE_DUPLICATES(boundaryAndBoundaryPlaneFacesList,err,error,*999)

    ! count number of faces that lie on boundary and boundary plane and are shared with other domains
    CALL LIST_DETACH_AND_DESTROY(boundaryAndBoundaryPlaneFacesList,numberBoundaryAndBoundaryPlaneFaces,integerArray,&
      & err,error,*999)
    ALLOCATE(boundaryAndBoundaryPlaneFaces(numberBoundaryAndBoundaryPlaneFaces))
    boundaryAndBoundaryPlaneFaces = integerArray(1:numberBoundaryAndBoundaryPlaneFaces)

    IF(ALLOCATED(integerArray)) DEALLOCATE(integerArray)

    !Allocate the array who's index will be 1 if that index of boundaryAndBoundaryPlaneFaces is on the boundary plane
    ALLOCATE(faceOnBoundaryPlane(numberBoundaryAndBoundaryPlaneFaces))
    faceOnBoundaryPlane=-1


    ! allocate lists of foreign domains in which boundary faces are present=. These will be the domains that have the relevant face as a ghost or boundary
    ALLOCATE(domainsOfFaceList(numberBoundaryAndBoundaryPlaneFaces),STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate domain list.",err,error,*999)

    ! allocate lists of foreign domains that share a boundary plane with the boundary face
    ALLOCATE(domainsOfBoundaryPlaneFaceList(numberBoundaryAndBoundaryPlaneFaces),STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate domain list.",err,error,*999)

    DO I=1, numberBoundaryAndBoundaryPlaneFaces
      NULLIFY(domainsOfBoundaryPlaneFaceList(I)%PTR)
      CALL LIST_CREATE_START(domainsOfBoundaryPlaneFaceList(I)%PTR,err,error,*999)
      CALL LIST_DATA_TYPE_SET(domainsOfBoundaryPlaneFaceList(I)%PTR,LIST_INTG_TYPE,err,error,*999)
      CALL LIST_INITIAL_SIZE_SET(domainsOfBoundaryPlaneFaceList(I)%PTR,elementsMapping%NUMBER_OF_ADJACENT_DOMAINS+1,err,error,*999)
      CALL LIST_CREATE_FINISH(domainsOfBoundaryPlaneFaceList(I)%PTR,err,error,*999)
    ENDDO

    DO I=1, numberBoundaryAndBoundaryPlaneFaces
      NULLIFY(domainsOfFaceList(I)%PTR)
      CALL LIST_CREATE_START(domainsOfFaceList(I)%PTR,err,error,*999)
      CALL LIST_DATA_TYPE_SET(domainsOfFaceList(I)%PTR,LIST_INTG_TYPE,err,error,*999)
      CALL LIST_INITIAL_SIZE_SET(domainsOfFaceList(I)%PTR,elementsMapping%NUMBER_OF_ADJACENT_DOMAINS+1,err,error,*999)
      CALL LIST_CREATE_FINISH(domainsOfFaceList(I)%PTR,err,error,*999)
    ENDDO


    !Counter for number of faces on the boundary plane
    numberBoundaryPlaneFaces=0

    ! fill domainsOfBoundaryPlaneFaceList with all foreign domains for each boundary plane face
    ! domainsOf BoundaryPlaneFaceList only includes the domains which are physically on the boundary plane

    !Allocate temporary array for global numbers of ghost elements
    ALLOCATE(tempArray(elementsMapping%NUMBER_OF_GHOST))
    tempArray=elementsMapping%LOCAL_TO_GLOBAL_MAP(elementsMapping%DOMAIN_LIST(elementsMapping%GHOST_START: &
      & elementsMapping%GHOST_FINISH))

    ! loop over boundary and boundary plane indices
    DO boundaryAndBoundaryPlaneFaceIdx=1,numberBoundaryAndBoundaryPlaneFaces
      faceGlobalNo=boundaryAndBoundaryPlaneFaces(boundaryAndBoundaryPlaneFaceIdx)

      ! loop over adjacent elements of this face
      DO adjacentElementIdx=1,topology%faces%faces(faceGlobalNo)%numberOfSurroundingElements
        adjacentElementGlobalNo=topology%faces%faces(faceGlobalNo)%surroundingElements(adjacentElementIdx)


        ! if adjacent element is among the ghost elements, i.e is also on another domain. The tempArray has the global numbers
        ! of the ghost elements from ghost start in index 1 to ghost finish in the final index, therefore we can get the element idx from the index in the array.
        IF (SORTED_ARRAY_CONTAINS_ELEMENT_INDEX(tempArray,adjacentElementGlobalNo,arrayIndex, &
          & err,error)) THEN

          adjacentElementLocalNo = elementsMapping%DOMAIN_LIST(elementsMapping%GHOST_START + arrayIndex-1)

          ! determine domain of adjacentElementLocalNo
          DO adjacentDomainIdx=1,elementsMapping%NUMBER_OF_ADJACENT_DOMAINS
            IF (SORTED_ARRAY_CONTAINS_ELEMENT(elementsMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%&
              & LOCAL_GHOST_RECEIVE_INDICES,adjacentElementLocalNo,err,error)) THEN

              domainNo = elementsMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%DOMAIN_NUMBER

              ! now it was found that faceGlobalNo is also on the boundary plane of domain domainNo, add to list
              CALL LIST_ITEM_ADD(domainsOfBoundaryPlaneFaceList(boundaryAndBoundaryPlaneFaceIdx)%PTR,domainNo,err,error,*999)

              faceOnBoundaryPlane(boundaryAndBoundaryPlaneFaceIdx)=1
              numberBoundaryPlaneFaces=numberBoundaryPlaneFaces+1

              !now check if any of the adjacent elements to this adjacent element is on another domain.
              !If it is add it to the domainsOfFaceList for this faces index, the rest of domainsOfFaceList gets assigned in the following section
              DO nodeIdx = 1,topology%ELEMENTS%ELEMENTS(adjacentElementGlobalNo)%BASIS%NUMBER_OF_NODES !Fix this, atm iterating through nodes then surrounding elems of those nodes is the only way to find surrounding elems (including diagonal elems)
                meshNodeNo=topology%ELEMENTS%ELEMENTS(adjacentElementGlobalNo)%MESH_ELEMENT_NODES(nodeIdx)
                DO surroundingElemIdx = 1,topology%NODES%NODES(meshNodeNo)%numberOfSurroundingElements
                  adjacentElementGlobalNo2 = topology%NODES%NODES(meshNodeNo)%surroundingElements(surroundingElemIdx)

                  domainNo2=decomposition%ELEMENT_DOMAIN(adjacentElementGlobalNo2) !Unsure if decomposition should be used here. If so, can use decomposition more in this subroutine.

                  IF(domainNo2/=domainNo .AND. domainNo2/=myComputationalNodeNumber) THEN

                    CALL LIST_ITEM_ADD(domainsOfFaceList(boundaryAndBoundaryPlaneFaceIdx)%PTR,domainNo2,err,error,*999)
                  ENDIF
                ENDDO !surroundingElemIdx
              ENDDO !nodeIdx
            ENDIF
          ENDDO  ! adjacentDomainIdx
        ENDIF
      ENDDO  ! adjacentElementIdx
    ENDDO  ! boundaryAndBoundaryPlaneFaceIdx

    IF(ALLOCATED(tempArray)) DEALLOCATE(tempArray)



    ALLOCATE(tempArray(elementsMapping%NUMBER_OF_BOUNDARY))
    tempArray=elementsMapping%LOCAL_TO_GLOBAL_MAP(elementsMapping%DOMAIN_LIST(elementsMapping%BOUNDARY_START: &
      & elementsMapping%BOUNDARY_FINISH))

    ! loop over boundary and boundary plane indices and assign to each face the domains that have it as a ghost or boundary plane
    DO boundaryAndBoundaryPlaneFaceIdx=1,numberBoundaryAndBoundaryPlaneFaces
      faceGlobalNo=boundaryAndBoundaryPlaneFaces(boundaryAndBoundaryPlaneFaceIdx)

      ! loop over adjacent elements of this face
      DO adjacentElementIdx=1,topology%faces%faces(faceGlobalNo)%numberOfSurroundingElements
        adjacentElementGlobalNo=topology%faces%faces(faceGlobalNo)%surroundingElements(adjacentElementIdx)


        ! if adjacent element is among the boundary or ghost elements, i.e is also on another domain. The tempArray has the global numbers
        ! of the boundary elements from boundary start in index 1 to boundary finish in the final index, therefore we can get the element idx from the index in the array.
        IF (SORTED_ARRAY_CONTAINS_ELEMENT_INDEX(tempArray,adjacentElementGlobalNo,arrayIndex, &
          & err,error)) THEN

          adjacentElementLocalNo = elementsMapping%DOMAIN_LIST(elementsMapping%BOUNDARY_START + arrayIndex-1)

          ! determine domain of adjacentElementLocalNo
          DO adjacentDomainIdx=1,elementsMapping%NUMBER_OF_ADJACENT_DOMAINS

            domainNo = elementsMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%DOMAIN_NUMBER

            IF (SORTED_ARRAY_CONTAINS_ELEMENT(elementsMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%&
              & LOCAL_GHOST_SEND_INDICES,adjacentElementLocalNo,err,error)) THEN

              ! now it was found that faceGlobalNo is also on domain domainNo, add to list
              CALL LIST_ITEM_ADD(domainsOfFaceList(boundaryAndBoundaryPlaneFaceIdx)%PTR,domainNo,err,error,*999)
            ENDIF
          ENDDO  ! adjacentDomainIdxDomainMappings_FacesCalculate
        ENDIF


      ENDDO  ! adjacentElementIdx
    ENDDO  ! boundaryAndBoundaryPlaneFaceIdx

    IF(ALLOCATED(tempArray)) DEALLOCATE(tempArray)




    !AdjacentDomainsList holds the domains that share a boundary plane (If the domain only shares a boundary plane node, but not a face it is not in adjacentDomainsList )
    NULLIFY(adjacentDomainsList)
    CALL LIST_CREATE_START(adjacentDomainsList,err,error,*999)
    CALL LIST_DATA_TYPE_SET(adjacentDomainsList,LIST_INTG_TYPE,err,error,*999)
    CALL LIST_CREATE_FINISH(adjacentDomainsList,err,error,*999)

    !extraAdjeacent Domains holds the domains which share ghost/boundary elements with the current domain
    NULLIFY(extraAdjacentDomainsList)
    CALL LIST_CREATE_START(extraAdjacentDomainsList,err,error,*999)
    CALL LIST_DATA_TYPE_SET(extraAdjacentDomainsList,LIST_INTG_TYPE,err,error,*999)
    CALL LIST_CREATE_FINISH(extraAdjacentDomainsList,err,error,*999)

    ! remove duplicate entries for the domains for the faces
    DO I=1, numberBoundaryAndBoundaryPlaneFaces
      CALL LIST_REMOVE_DUPLICATES(domainsOfBoundaryPlaneFaceList(I)%PTR,err,error,*999)
      CALL LIST_REMOVE_DUPLICATES(domainsOfFaceList(I)%PTR,err,error,*999)

      ! add adjacent domains to adjacentDomainsList
      CALL LIST_NUMBER_OF_ITEMS_GET(domainsOfBoundaryPlaneFaceList(I)%PTR,numberDomains,err,error,*999)
      DO J=1,numberDomains
        CALL LIST_ITEM_GET(domainsOfBoundaryPlaneFaceList(I)%PTR,J,adjacentDomain,err,error,*999)
        CALL LIST_ITEM_ADD(adjacentDomainsList,adjacentDomain,err,error,*999)
      ENDDO

      ! add adjacent domains to extraAdjacentDomainsList
      CALL LIST_NUMBER_OF_ITEMS_GET(domainsOfFaceList(I)%PTR,numberDomains,err,error,*999)
      DO J=1,numberDomains
        CALL LIST_ITEM_GET(domainsOfFaceList(I)%PTR,J,extraAdjacentDomain,err,error,*999)
        CALL LIST_ITEM_ADD(extraAdjacentDomainsList,extraAdjacentDomain,err,error,*999)
      ENDDO
    ENDDO

    ! determine distinct list of adjacent domains
    CALL LIST_REMOVE_DUPLICATES(adjacentDomainsList,err,error,*999)
    CALL LIST_REMOVE_DUPLICATES(extraAdjacentDomainsList,err,error,*999)

    ! create sorted list that contains local domain and all adjacent domains that share a boundary plane
    NULLIFY(localAndAdjacentDomainsList)
    CALL LIST_CREATE_START(localAndAdjacentDomainsList,err,error,*999)
    CALL LIST_DATA_TYPE_SET(localAndAdjacentDomainsList,LIST_INTG_TYPE,err,error,*999)
    CALL LIST_CREATE_FINISH(localAndAdjacentDomainsList,err,error,*999)
    CALL LIST_ITEM_ADD(localAndAdjacentDomainsList,myComputationalNodeNumber,err,error,*999)
    CALL LIST_APPENDLIST(localAndAdjacentDomainsList,adjacentDomainsList,err,error,*999)
    CALL LIST_SORT(localAndAdjacentDomainsList,err,error,*999)

    !numberAdjacentDomains is the number of domains that share a boundary plane face with the local domain
    CALL LIST_DETACH_AND_DESTROY(adjacentDomainsList,numberAdjacentDomains,integerArray,err,error,*999)
    ALLOCATE(adjacentDomains(numberAdjacentDomains))
    adjacentDomains = integerArray(1:numberAdjacentDomains)
    IF(ALLOCATED(integerArray)) DEALLOCATE(integerArray)

    !numberExtraAdjacentDomains is the number of domains that will share ghost/boundary faces with the local domain
    CALL LIST_DETACH_AND_DESTROY(extraAdjacentDomainsList,numberExtraAdjacentDomains,integerArray,err,error,*999)
    ALLOCATE(extraAdjacentDomains(numberExtraAdjacentDomains))
    extraAdjacentDomains = integerArray(1:numberExtraAdjacentDomains)
    IF(ALLOCATED(integerArray)) DEALLOCATE(integerArray)

    !numberLocalAndAdjacentDomains equals numberAdjacentDomains + 1, adding one for the local domain
    CALL LIST_DETACH_AND_DESTROY(localAndAdjacentDomainsList,numberLocalAndAdjacentDomains,integerArray,&
      & err,error,*999)
    ALLOCATE(localAndAdjacentDomains(numberLocalAndAdjacentDomains))
    localAndAdjacentDomains = integerArray(1:numberLocalAndAdjacentDomains)
    IF(ALLOCATED(integerArray)) DEALLOCATE(integerArray)

    ! create list for each adjacent domain with shared faces at the boundary plane
    ALLOCATE(sharedFacesList(numberAdjacentDomains),STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate shared faces list.",err,error,*999)

    DO adjacentDomainIdx=1,numberAdjacentDomains
      NULLIFY(sharedFacesList(adjacentDomainIdx)%PTR)
      CALL LIST_CREATE_START(sharedFacesList(adjacentDomainIdx)%PTR,err,error,*999)
      CALL LIST_DATA_TYPE_SET(sharedFacesList(adjacentDomainIdx)%PTR,LIST_INTG_TYPE,err,error,*999)
      CALL LIST_CREATE_FINISH(sharedFacesList(adjacentDomainIdx)%PTR,err,error,*999)
    ENDDO

    ! fill sharedFacesList
    DO I=1,numberBoundaryAndBoundaryPlaneFaces

      ! loop over adjacent domains of face I
      CALL LIST_NUMBER_OF_ITEMS_GET(domainsOfBoundaryPlaneFaceList(I)%PTR,numberDomains,err,error,*999)
      DO J=1,numberDomains
        CALL LIST_ITEM_GET(domainsOfBoundaryPlaneFaceList(I)%PTR,J,adjacentDomain,err,error,*999)

        ! get index of sharedFacesList
        IF (SORTED_ARRAY_CONTAINS_ELEMENT_INDEX(adjacentDomains,&
          & adjacentDomain,adjacentDomainIdx,err,error)) THEN

          ! add face to sharedFaceslist of domain adjacentDomainIdx
          CALL LIST_ITEM_ADD(sharedFacesList(adjacentDomainIdx)%PTR,I,err,error,*999)
        ENDIF
      ENDDO
    ENDDO


    ! determine total number of faces on all ranks

    ! count number of faces where boundary plane faces are counted as the resp. fraction such that the sum is 1 for all processes
    numberFaces = REAL(facesMapping%NUMBER_OF_INTERNAL,DP)

    DO I=1,numberBoundaryAndBoundaryPlaneFaces
      IF(faceOnBoundaryPlane(I)==1) THEN
        CALL LIST_NUMBER_OF_ITEMS_GET(domainsOfBoundaryPlaneFaceList(I)%PTR,numberDomains,err,error,*999)
        numberFaces = numberFaces + 1.0_DP/(REAL(numberDomains,DP)+1.0_DP)
      ELSE
        numberFaces = numberFaces + 1.0_DP
      ENDIF
    ENDDO

    ! allreduce number of faces
    CALL MPI_ALLREDUCE(numberFaces,totalNumberFaces,1,MPI_DOUBLE,MPI_SUM, &
      & computationalEnvironment%mpiCommunicator,MPI_IERROR)
    CALL MPI_ERROR_CHECK("MPI_ALLREDUCE",MPI_IERROR,err,error,*999)
    facesMapping%NUMBER_OF_GLOBAL = NINT(totalNumberFaces)


    ! compute average number per domain
    facesMapping%NUMBER_OF_DOMAINS = elementsMapping%NUMBER_OF_DOMAINS
    optimalNumberFacesPerDomain = REAL(facesMapping%NUMBER_OF_GLOBAL,DP) / facesMapping%NUMBER_OF_DOMAINS

    ! exchange number of local faces among adjacent ranks
    numberLocalFaces = facesMapping%NUMBER_OF_INTERNAL + numberBoundaryAndBoundaryPlaneFaces
    !First entry is the number of local faces, not including boundary plane or ghost faces
    !Second entry is the number of local faces, including the boundary plane but not ghosts
    numberNonBoundaryPlaneAndLocalFaces(1) = numberLocalFaces-numberBoundaryPlaneFaces
    numberNonBoundaryPlaneAndLocalFaces(2) = numberLocalFaces

    ! allocate request handles
    ALLOCATE(sendRequestHandle(numberLocalAndAdjacentDomains), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate sendRequestHandle array with size "//&
      & TRIM(NUMBER_TO_VSTRING(numberAdjacentDomains+1,"*",err,error))//".",err,error,*999)

    ALLOCATE(receiveRequestHandle(numberLocalAndAdjacentDomains), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate receiveRequestHandle array with size "//&
      & TRIM(NUMBER_TO_VSTRING(numberLocalAndAdjacentDomains,"*",err,error))//".",err,error,*999)

    ! allocate receive buffer (2 entries for interior and totally stored local faces, adjacent domains + local domain)
    ALLOCATE(numberNonBoundaryPlaneAndLocalFacesOnRank(2,numberAdjacentDomains+1), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate numberNonBoundaryPlaneAndLocalFacesOnRank array with size "//&
      & TRIM(NUMBER_TO_VSTRING(2*(numberLocalAndAdjacentDomains),"*",err,error))//".",err,error,*999)

    ! commit send commands
    DO adjacentDomainIdx=1,numberLocalAndAdjacentDomains
      adjacentDomain = localAndAdjacentDomains(adjacentDomainIdx)

      CALL MPI_ISEND(numberNonBoundaryPlaneAndLocalFaces, 2, MPI_INT, adjacentDomain, 0, &
        & computationalEnvironment%mpiCommunicator, sendRequestHandle(adjacentDomainIdx), MPI_IERROR)
      CALL MPI_ERROR_CHECK("MPI_ISEND",MPI_IERROR,err,error,*999)
    ENDDO

    ! commit receive commands
    DO adjacentDomainIdx=1,numberLocalAndAdjacentDomains
      adjacentDomain = localAndAdjacentDomains(adjacentDomainIdx)
      CALL MPI_IRECV(numberNonBoundaryPlaneAndLocalFacesOnRank(:,adjacentDomainIdx), 2, MPI_INT, adjacentDomain, 0, &
        & computationalEnvironment%mpiCommunicator, receiveRequestHandle(adjacentDomainIdx), MPI_IERROR)
      CALL MPI_ERROR_CHECK("MPI_IRECV",MPI_IERROR,err,error,*999)
    ENDDO

    ! wait for all communication to finish
    CALL MPI_WAITALL(numberLocalAndAdjacentDomains, sendRequestHandle, MPI_STATUSES_IGNORE, MPI_IERROR)
    CALL MPI_ERROR_CHECK("MPI_WAITALL",MPI_IERROR,err,error,*999)

    CALL MPI_WAITALL(numberLocalAndAdjacentDomains, receiveRequestHandle, MPI_STATUSES_IGNORE, MPI_IERROR)
    CALL MPI_ERROR_CHECK("MPI_WAITALL",MPI_IERROR,err,error,*999)

    ! assign boundary faces to domains
    ! allocate boundaryAndBoundaryPlaneFacesDomain
    ALLOCATE(boundaryAndBoundaryPlaneFacesDomain(numberBoundaryAndBoundaryPlaneFaces), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate boundaryAndBoundaryPlaneFacesDomain array with size "//&
      & TRIM(NUMBER_TO_VSTRING(numberBoundaryAndBoundaryPlaneFaces,"*",err,error))//".",err,error,*999)
    boundaryAndBoundaryPlaneFacesDomain = -1

    ALLOCATE(numberFacesInDomain(numberLocalAndAdjacentDomains), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate numberFacesInDomain array with size "//&
      & TRIM(NUMBER_TO_VSTRING(numberLocalAndAdjacentDomains,"*",err,error))//".",err,error,*999)
    numberFacesInDomain = 0



    ! add local domain to domain list of each face
    DO boundaryAndBoundaryPlaneFaceIdx=1,numberBoundaryAndBoundaryPlaneFaces
      CALL LIST_ITEM_ADD(domainsOfBoundaryPlaneFaceList(boundaryAndBoundaryPlaneFaceIdx)%PTR,myComputationalNodeNumber, &
        & err,error,*999)
      CALL LIST_SORT(domainsOfBoundaryPlaneFaceList(boundaryAndBoundaryPlaneFaceIdx)%PTR,err,error,*999)
      !Assign local domain to the boundary faces that are not on the boundary plane
      IF(faceOnBoundaryPlane(boundaryAndBoundaryPlaneFaceIdx) == -1) THEN
        boundaryAndBoundaryPlaneFacesDomain(boundaryAndBoundaryPlaneFaceIdx) = myComputationalNodeNumber
      ENDIF
    ENDDO

    ! add local domain to domain list of each face
    DO boundaryAndBoundaryPlaneFaceIdx=1,numberBoundaryAndBoundaryPlaneFaces
      CALL LIST_ITEM_ADD(domainsOfFaceList(boundaryAndBoundaryPlaneFaceIdx)%PTR,myComputationalNodeNumber,err,error,*999)
      CALL LIST_SORT(domainsOfFaceList(boundaryAndBoundaryPlaneFaceIdx)%PTR,err,error,*999)
    ENDDO


    ! loop over adjacent domains
    DO adjacentDomainIdx=1,numberAdjacentDomains
      adjacentDomain = adjacentDomains(adjacentDomainIdx)


      ! loop over adjacent faces on that adjacent domain
      CALL LIST_NUMBER_OF_ITEMS_GET(sharedFacesList(adjacentDomainIdx)%PTR,numberSharedFaces,err,error,*999)
      DO sharedFaceIdx = 1,numberSharedFaces
        CALL LIST_ITEM_GET(sharedFacesList(adjacentDomainIdx)%PTR,sharedFaceIdx,boundaryAndBoundaryPlaneFaceIdx,&
          & err,error,*999)



        ! if face was not yet assigned to a domain (This array was initialised earlier in the subroutine to be -1)
        IF (boundaryAndBoundaryPlaneFacesDomain(boundaryAndBoundaryPlaneFaceIdx) == -1) THEN
          ! note: this face is shared by the domains in domainsOfBoundaryPlaneFaceList(boundaryAndBoundaryPlaneFaceIdx) (includes local domain)

          numberFacesWithThatSetOfDomains = 0

          ! loop over all further faces to find other faces that are shared by the same domains, count total number of them
          DO sharedFaceIdx2 = sharedFaceIdx,numberSharedFaces
            CALL LIST_ITEM_GET(sharedFacesList(adjacentDomainIdx)%PTR,sharedFaceIdx2,boundaryAndBoundaryPlaneFaceIdx2,&
              & err,error,*999)

            IF (boundaryAndBoundaryPlaneFacesDomain(boundaryAndBoundaryPlaneFaceIdx2) == -1) THEN

              !if the domain list of each boundary face is equal then add 1 to the number of faces with that set of domains.
              IF (LIST_EQUAL(domainsOfBoundaryPlaneFaceList(boundaryAndBoundaryPlaneFaceIdx)%PTR, &
                & domainsOfBoundaryPlaneFaceList(boundaryAndBoundaryPlaneFaceIdx2)%PTR,err,error)) THEN

                numberFacesWithThatSetOfDomains = numberFacesWithThatSetOfDomains+1
              ENDIF
            ENDIF
          ENDDO

          ! get first of the shared domains
          numberFacesInDomain = 0
          domainToAssignFacesToIdx = 1
          CALL LIST_ITEM_GET(domainsOfBoundaryPlaneFaceList(boundaryAndBoundaryPlaneFaceIdx)%PTR,domainToAssignFacesToIdx, &
            & domainToAssignFacesTo,err,error,*999)
          CALL LIST_NUMBER_OF_ITEMS_GET(domainsOfBoundaryPlaneFaceList(boundaryAndBoundaryPlaneFaceIdx)%PTR, &
            & numberDomains,err,error,*999)

          ! again loop over all further faces with the same domains, assign them to domains
          DO sharedFaceIdx2 = sharedFaceIdx,numberSharedFaces
            CALL LIST_ITEM_GET(sharedFacesList(adjacentDomainIdx)%PTR,sharedFaceIdx2,boundaryAndBoundaryPlaneFaceIdx2,&
                & err,error,*999)

            !if the domain list of each boundary face is equal
            IF(LIST_EQUAL(domainsOfBoundaryPlaneFaceList(boundaryAndBoundaryPlaneFaceIdx)%PTR, &
              & domainsOfBoundaryPlaneFaceList(boundaryAndBoundaryPlaneFaceIdx2)%PTR,err,error)) THEN


              !FIXTHIS should iterate DO domainToAssignFacesToIdx = 1,2 for faces, leave as is for now so it is more similar to what it should be for nodes.
              DO

                ! find index for numberNonBoundaryPlaneAndLocalFacesOnRank that corresponds to domain domainToAssignFacesTo
                adjacentDomainIdx2 = 1
                DO I=1,numberLocalAndAdjacentDomains
                  adjacentDomain = localAndAdjacentDomains(I)
                  IF (adjacentDomain == domainToAssignFacesTo) THEN
                    adjacentDomainIdx2 = I
                    EXIT
                  ENDIF
                ENDDO

                ! compute the number of faces that this domain will get from the current set of faces
                numberLocalFacesOnRank = numberNonBoundaryPlaneAndLocalFacesOnRank(2,adjacentDomainIdx2)
                numberNonBoundaryFacesOnRank = numberNonBoundaryPlaneAndLocalFacesOnRank(1,adjacentDomainIdx2)

                numberFacesAboveOptimum = numberLocalFacesOnRank - optimalNumberFacesPerDomain
                numberSharedFacesOnRank = numberLocalFacesOnRank - numberNonBoundaryFacesOnRank

                ! compute the portion of each face that adjacent domain should get from other domains
                ! E.g. if portionToDistribute=0.4 that means that 4 out of 10 shared faces of the adjacent domain should be assigned to other domains and 6 should remain their own
                portionToDistribute = numberFacesAboveOptimum / numberSharedFacesOnRank

                ! compute the number of faces from the current set of faces that have the same domains that should belong to adjacent domain
                numberInCurrentSetToClaim = NINT((1.0 - portionToDistribute) * numberFacesWithThatSetOfDomains)

                ! if there weren't enough faces assigned to adjacent domain domainToAssignFacesToIdx yet, the domain which will claim this face is found
                IF (numberFacesInDomain(domainToAssignFacesToIdx) < numberInCurrentSetToClaim) THEN
                  EXIT
                ELSE
                  ! if there are no further domainDOFS_MAPPINGs, exit trying to find the next domain
                  IF (domainToAssignFacesToIdx == numberDomains) EXIT

                  ! now that domain has got enough faces, get the next domain
                  domainToAssignFacesToIdx = domainToAssignFacesToIdx + 1
                  CALL LIST_ITEM_GET(domainsOfBoundaryPlaneFaceList(boundaryAndBoundaryPlaneFaceIdx2)%PTR, &
                    & domainToAssignFacesToIdx, domainToAssignFacesTo,err,error,*999)
                ENDIF
              ENDDO

              ! assign face sharedFaceIdx2 to domain domainToAssignFacesTo
              boundaryAndBoundaryPlaneFacesDomain(boundaryAndBoundaryPlaneFaceIdx2) = domainToAssignFacesTo

              ! increment count of faces that this domain has claimed in the current set
              numberFacesInDomain(domainToAssignFacesToIdx) = numberFacesInDomain(domainToAssignFacesToIdx) + 1

            ENDIF
          ENDDO  ! sharedFaceIdx2
        ENDIF  ! face not yet assigned to domain

      ENDDO  ! sharedFaceIdx
    ENDDO  ! adjacentDomainIdx

    ! fill local numbering arrays

    ! create list to hold boundary faces
    NULLIFY(boundaryFacesList)
    CALL LIST_CREATE_START(boundaryFacesList,err,error,*999)
    CALL LIST_DATA_DIMENSION_SET(boundaryFacesList,1,err,error,*999)
    CALL LIST_DATA_TYPE_SET(boundaryFacesList,LIST_INTG_TYPE,err,error,*999)
    CALL LIST_INITIAL_SIZE_SET(boundaryFacesList,CEILING(elementsMapping%NUMBER_OF_LOCAL*0.2),err,error,*999)
    CALL LIST_CREATE_FINISH(boundaryFacesList,err,error,*999)

    ! count number of boundary faces from boundary and boundary plane faces
    DO boundaryAndBoundaryPlaneFaceIdx=1,numberBoundaryAndBoundaryPlaneFaces
      domainNo = boundaryAndBoundaryPlaneFacesDomain(boundaryAndBoundaryPlaneFaceIdx)

      ! if face is a boundary faces and stays on own domain
      IF (domainNo == myComputationalNodeNumber) THEN
        CALL LIST_ITEM_ADD(boundaryFacesList,boundaryAndBoundaryPlaneFaceIdx,err,error,*999)
      ENDIF
    ENDDO

    ! extract arrays of local boundary faces
    CALL LIST_DETACH_AND_DESTROY(boundaryFacesList, facesMapping%NUMBER_OF_BOUNDARY, integerArray, err,error,*999)
    ALLOCATE(boundaryFaces(facesMapping%NUMBER_OF_BOUNDARY))
    boundaryFaces=integerArray(1:facesMapping%NUMBER_OF_BOUNDARY)
    IF(ALLOCATED(integerArray)) DEALLOCATE(integerArray)


    ! create list of ghost faces with their home domain
    NULLIFY(ghostFacesDomainsList)
    CALL LIST_CREATE_START(ghostFacesDomainsList,err,error,*999)
    CALL LIST_DATA_DIMENSION_SET(ghostFacesDomainsList,2,err,error,*999)
    CALL LIST_DATA_TYPE_SET(ghostFacesDomainsList,LIST_INTG_TYPE,err,error,*999)
    CALL LIST_INITIAL_SIZE_SET(ghostFacesDomainsList,MAX(1,numberBoundaryAndBoundaryPlaneFaces),err,error,*999)
    CALL LIST_CREATE_FINISH(ghostFacesDomainsList,err,error,*999)

    ! Now exchange the boundary faces that the current domain owns to domains with these faces as ghost faces
    ! allocate send buffers
    ALLOCATE(sendBufferList(elementsMapping%NUMBER_OF_ADJACENT_DOMAINS), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate sendBufferList array with size "//&
      & TRIM(NUMBER_TO_VSTRING(elementsMapping%NUMBER_OF_ADJACENT_DOMAINS,"*",err,error))//".",err,error,*999)

    ALLOCATE(sendRequestHandle0(elementsMapping%NUMBER_OF_ADJACENT_DOMAINS), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate sendRequestHandle0 array with size "//&
      & TRIM(NUMBER_TO_VSTRING(elementsMapping%NUMBER_OF_ADJACENT_DOMAINS,"*",err,error))//".",err,error,*999)

    ALLOCATE(sendRequestHandle1(elementsMapping%NUMBER_OF_ADJACENT_DOMAINS), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate sendRequestHandle1 array with size "//&
      & TRIM(NUMBER_TO_VSTRING(elementsMapping%NUMBER_OF_ADJACENT_DOMAINS,"*",err,error))//".",err,error,*999)

    DO I=1,elementsMapping%NUMBER_OF_ADJACENT_DOMAINS
      NULLIFY(sendBufferList(I)%PTR)
      CALL LIST_CREATE_START(sendBufferList(I)%PTR,err,error,*999)
      CALL LIST_DATA_DIMENSION_SET(sendBufferList(I)%PTR,1,err,error,*999)
      CALL LIST_DATA_TYPE_SET(sendBufferList(I)%PTR,LIST_INTG_TYPE,err,error,*999)
      CALL LIST_INITIAL_SIZE_SET(sendBufferList(I)%PTR,10,err,error,*999)
      CALL LIST_CREATE_FINISH(sendBufferList(I)%PTR,err,error,*999)
    ENDDO

    ! add own boundary and boundary plane faces that are ghost faces on other domains to send buffer for the domains that they will be sent to.

    ! loop over boundary (and boundary plane) faces
    DO boundaryAndBoundaryPlaneFaceIdx=1, numberBoundaryAndBoundaryPlaneFaces
      faceGlobalNo=boundaryAndBoundaryPlaneFaces(boundaryAndBoundaryPlaneFaceIdx)

      ! get the domain that owns the face
      domainNo = boundaryAndBoundaryPlaneFacesDomain(boundaryAndBoundaryPlaneFaceIdx)

      ! only add to send buffer if it is owned by own domain
      IF (domainNo == myComputationalNodeNumber) THEN

        !Loop over adjacent domains
        DO domainIdx=1,elementsMapping%NUMBER_OF_ADJACENT_DOMAINS

          domainNo2 = elementsMapping%ADJACENT_DOMAINS(DomainIdx)%DOMAIN_NUMBER

          !If domainNo2 has faceGlobalNo as a ghost face we assign it to sendbufferList of domainNo2 which has index domainIdx
          CALL LIST_NUMBER_OF_ITEMS_GET(domainsOfFaceList(boundaryAndBoundaryPlaneFaceIdx)%PTR,numberDomains, &
            & err,error,*999)
          DO I=1,numberDomains
            CALL LIST_ITEM_GET(domainsOfFaceList(boundaryAndBoundaryPlaneFaceIdx)%PTR,I, &
              & domainNo3,err,error,*999)

            IF (domainNo2 == domainNo3) THEN
              CALL LIST_ITEM_ADD(sendBufferList(domainIdx)%PTR, faceGlobalNo, err,error,*999)
            ENDIF
          ENDDO !I
        ENDDO !DomainIdx
      ENDIF
    ENDDO

    ! remove duplicates and sort list

    maximumNumberToSend = 0
    DO domainIdx=1,elementsMapping%NUMBER_OF_ADJACENT_DOMAINS
      domainNo = elementsMapping%ADJACENT_DOMAINS(domainIdx)%DOMAIN_NUMBER

      CALL LIST_REMOVE_DUPLICATES(sendBufferList(domainIdx)%PTR,err,error,*999)
      CALL LIST_NUMBER_OF_ITEMS_GET(sendBufferList(domainIdx)%PTR,numberToSend,err,error,*999)
      maximumNumberToSend = MAX(maximumNumberToSend,numberToSend)
    ENDDO

    ALLOCATE(sendBuffer(maximumNumberToSend,elementsMapping%NUMBER_OF_ADJACENT_DOMAINS), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate sendBuffer array with size "//&
      & TRIM(NUMBER_TO_VSTRING(maximumNumberToSend,"*",err,error))//"x"//&
      & TRIM(NUMBER_TO_VSTRING(elementsMapping%NUMBER_OF_ADJACENT_DOMAINS,"*",err,error))//".",err,error,*999)

    ALLOCATE(numberToSendToDomain(elementsMapping%NUMBER_OF_ADJACENT_DOMAINS), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate numberToSendToDomain array with size "//&
      & TRIM(NUMBER_TO_VSTRING(elementsMapping%NUMBER_OF_ADJACENT_DOMAINS,"*",err,error))//".",err,error,*999)

    ! commit send calls
    DO domainIdx=1,elementsMapping%NUMBER_OF_ADJACENT_DOMAINS
      domainNo = elementsMapping%ADJACENT_DOMAINS(domainIdx)%DOMAIN_NUMBER
      CALL LIST_DETACH_AND_DESTROY(sendBufferList(domainIdx)%PTR,numberToSendToDomain(domainIdx),&
        & integerArray,err,error,*999)
      sendBuffer(1:numberToSendToDomain(domainIdx),domainIdx) = integerArray(1:numberToSendToDomain(domainIdx))
      IF(ALLOCATED(integerArray)) DEALLOCATE(integerArray)


      ! number of faces to be send to domain
      CALL MPI_ISEND(numberToSendToDomain(domainIdx),1,MPI_INT,domainNo,0, &
        & computationalEnvironment%mpiCommunicator, sendRequestHandle0(domainIdx), MPI_IERROR)
      CALL MPI_ERROR_CHECK("MPI_ISEND",MPI_IERROR,err,error,*999)

      ! actual global face numbers to send
      IF (numberToSendToDomain(domainIdx) > 0) THEN
        CALL MPI_ISEND(sendBuffer(1:numberToSendToDomain(domainIdx),domainIdx),numberToSendToDomain(domainIdx), &
          & MPI_INT,domainNo,1,computationalEnvironment%mpiCommunicator, sendRequestHandle1(domainIdx), MPI_IERROR)
        CALL MPI_ERROR_CHECK("MPI_ISEND",MPI_IERROR,err,error,*999)
      ENDIF
    ENDDO

    ! receive number of faces to receive
    DO domainIdx=1,elementsMapping%NUMBER_OF_ADJACENT_DOMAINS
      domainNo = elementsMapping%ADJACENT_DOMAINS(domainIdx)%DOMAIN_NUMBER

      CALL MPI_RECV(numberOfFacesToReceive,1,MPI_INT,domainNo,0,computationalEnvironment%mpiCommunicator,MPI_STATUS_IGNORE, &
        & MPI_IERROR)
      CALL MPI_ERROR_CHECK("MPI_RECV",MPI_IERROR,err,error,*999)

      IF (numberOfFacesToReceive>0) THEN
        ALLOCATE(receiveBuffer(numberOfFacesToReceive), STAT=err)
        IF(err/=0) CALL FlagError("Could not allocate receiveBuffer array with size "//&
          & TRIM(NUMBER_TO_VSTRING(numberOfFacesToReceive,"*",err,error))//".",err,error,*999)

        CALL MPI_RECV(receiveBuffer,numberOfFacesToReceive,MPI_INT,domainNo,1, &
          & computationalEnvironment%mpiCommunicator,MPI_STATUS_IGNORE,MPI_IERROR)
        CALL MPI_ERROR_CHECK("MPI_RECV",MPI_IERROR,err,error,*999)

        ! store received ghost faces with domain in ghostFacesDomainsList
        DO I=1,numberOfFacesToReceive
          ghostFaceGlobalNo = receiveBuffer(I)
          ghostDomain = domainNo
          CALL LIST_ITEM_ADD(ghostFacesDomainsList,[ghostFaceGlobalNo,ghostDomain],err,error,*999)
        ENDDO


        IF(ALLOCATED(receiveBuffer)) DEALLOCATE(receiveBuffer)

      ENDIF
    ENDDO

    ! wait for all communication to finish (Not needed because we use a MPI_RECV not an MPI_IRECV)
    !CALL MPI_WAITALL(elementsMapping%NUMBER_OF_ADJACENT_DOMAINS, sendRequestHandle0, MPI_STATUSES_IGNORE, MPI_IERROR)
    !CALL MPI_ERROR_CHECK("MPI_WAITALL",MPI_IERROR,err,error,*999)

    !CALL MPI_WAITALL(elementsMapping%NUMBER_OF_ADJACENT_DOMAINS, sendRequestHandle1, MPI_STATUSES_IGNORE, MPI_IERROR)
    !CALL MPI_ERROR_CHECK("MPI_WAITALL",MPI_IERROR,err,error,*999)

    !ghostFacesDomains is size (2,number of ghost) where the first entry is the global face number and the second is the domain number of the domain that owns the face
    CALL LIST_SORT(ghostFacesDomainsList,err,error,*999)
    CALL LIST_DETACH_AND_DESTROY(ghostFacesDomainsList,facesMapping%NUMBER_OF_GHOST,integerArray2D,err,error,*999)
    ALLOCATE(ghostFacesDomains(2,facesMapping%NUMBER_OF_GHOST))
    ghostFacesDomains(1,1:facesMapping%NUMBER_OF_GHOST)=integerArray2D(1,1:facesMapping%NUMBER_OF_GHOST)
    ghostFacesDomains(2,1:facesMapping%NUMBER_OF_GHOST)=integerArray2D(2,1:facesMapping%NUMBER_OF_GHOST)

    IF(ALLOCATED(integerArray2D)) DEALLOCATE(integerArray2D)

    !From here on we use numberExtraAdjacentDomains not numberAdjacentDomains because we want the number of domains that communicate ghost/boundary faces

    ! initialize facesMapping%ADJACENT_DOMAINS. Here we want the number of domains that will send/recieve faces with this rank
    facesMapping%NUMBER_OF_ADJACENT_DOMAINS = numberExtraAdjacentDomains

    ! allocate ADJACENT_DOMAINS
    ALLOCATE(facesMapping%ADJACENT_DOMAINS(numberExtraAdjacentDomains), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate adjacent domains array with size "//&
      & TRIM(NUMBER_TO_VSTRING(numberExtraAdjacentDomains,"*",err,error))//".",err,error,*999)

    DO adjacentDomainIdx=1,numberExtraAdjacentDomains
      adjacentDomain = extraAdjacentDomains(adjacentDomainIdx)
      facesMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%DOMAIN_NUMBER = adjacentDomain
      facesMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%NUMBER_OF_SEND_GHOSTS = 0
      facesMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%NUMBER_OF_RECEIVE_GHOSTS = 0
      facesMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%NUMBER_OF_FURTHER_LINKED_GHOSTS = 0
    ENDDO

    ! store number of local and total number of local faces
    facesMapping%NUMBER_OF_LOCAL = facesMapping%NUMBER_OF_INTERNAL + facesMapping%NUMBER_OF_BOUNDARY
    facesMapping%TOTAL_NUMBER_OF_LOCAL = facesMapping%NUMBER_OF_LOCAL + facesMapping%NUMBER_OF_GHOST

    facesMapping%INTERNAL_START=1
    facesMapping%INTERNAL_FINISH=facesMapping%INTERNAL_START+facesMapping%NUMBER_OF_INTERNAL-1
    facesMapping%BOUNDARY_START=facesMapping%INTERNAL_FINISH+1
    facesMapping%BOUNDARY_FINISH=facesMapping%BOUNDARY_START+facesMapping%NUMBER_OF_BOUNDARY-1
    facesMapping%GHOST_START=facesMapping%BOUNDARY_FINISH+1
    facesMapping%GHOST_FINISH=facesMapping%GHOST_START+facesMapping%NUMBER_OF_GHOST-1

    ! allocate LOCAL_TO_GLOBAL_MAP
    ALLOCATE(facesMapping%LOCAL_TO_GLOBAL_MAP(facesMapping%TOTAL_NUMBER_OF_LOCAL), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate faces mapping local to global map with size "//&
      & TRIM(NUMBER_TO_VSTRING(facesMapping%TOTAL_NUMBER_OF_LOCAL,"*",err,error))//".",err,error,*999)

    ! allocate DOMAIN_LIST
    ALLOCATE(facesMapping%DOMAIN_LIST(facesMapping%TOTAL_NUMBER_OF_LOCAL), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate faces mapping domain list with size "//&
      & TRIM(NUMBER_TO_VSTRING(facesMapping%TOTAL_NUMBER_OF_LOCAL,"*",err,error))//".",err,error,*999)

    ! create lists for local ghost send and receive indices
    ALLOCATE(localGhostSendIndices(numberExtraAdjacentDomains), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate localGhostSendIndices with size "//&
      & TRIM(NUMBER_TO_VSTRING(numberExtraAdjacentDomains,"*",err,error))//".",err,error,*999)

    ALLOCATE(localGhostReceiveIndices(numberExtraAdjacentDomains), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate localGhostReceiveIndices with size "//&
      & TRIM(NUMBER_TO_VSTRING(numberExtraAdjacentDomains,"*",err,error))//".",err,error,*999)

    DO adjacentDomainIdx=1,numberExtraAdjacentDomains

      ! create list for local ghost send indices
      NULLIFY(localGhostSendIndices(adjacentDomainIdx)%PTR)
      CALL LIST_CREATE_START(localGhostSendIndices(adjacentDomainIdx)%PTR,err,error,*999)
      CALL LIST_DATA_DIMENSION_SET(localGhostSendIndices(adjacentDomainIdx)%PTR,1,err,error,*999)
      CALL LIST_DATA_TYPE_SET(localGhostSendIndices(adjacentDomainIdx)%PTR,LIST_INTG_TYPE,err,error,*999)
      CALL LIST_INITIAL_SIZE_SET(localGhostSendIndices(adjacentDomainIdx)%PTR,MAX(1,numberBoundaryAndBoundaryPlaneFaces),&
        & err,error,*999)
      CALL LIST_CREATE_FINISH(localGhostSendIndices(adjacentDomainIdx)%PTR,err,error,*999)

      ! create list for local ghost receive indices
      NULLIFY(localGhostReceiveIndices(adjacentDomainIdx)%PTR)
      CALL LIST_CREATE_START(localGhostReceiveIndices(adjacentDomainIdx)%PTR,err,error,*999)
      CALL LIST_DATA_DIMENSION_SET(localGhostReceiveIndices(adjacentDomainIdx)%PTR,1,err,error,*999)
      CALL LIST_DATA_TYPE_SET(localGhostReceiveIndices(adjacentDomainIdx)%PTR,LIST_INTG_TYPE,err,error,*999)
      CALL LIST_INITIAL_SIZE_SET(localGhostReceiveIndices(adjacentDomainIdx)%PTR,MAX(1,numberBoundaryAndBoundaryPlaneFaces),&
        & err,error,*999)
      CALL LIST_CREATE_FINISH(localGhostReceiveIndices(adjacentDomainIdx)%PTR,err,error,*999)
    ENDDO

    ! internalFaces contains the global numbers of the internal faces

    ! loop over internal and boundary faces and assign local face numbers
    internalFacesIdx = 1
    boundaryFacesIdx = 1
    localFaceNo = 1
    domainListInternalIdx = facesMapping%INTERNAL_START
    domainListBoundaryIdx = facesMapping%BOUNDARY_START
    DO WHILE(internalFacesIdx <= facesMapping%NUMBER_OF_INTERNAL &
      & .OR. boundaryFacesIdx <= facesMapping%NUMBER_OF_BOUNDARY)

      ! get next internal or boundary face, ascending with global face number, if there are no more internal or boundary faces, set to -1
      IF (boundaryFacesIdx <= facesMapping%NUMBER_OF_BOUNDARY) THEN
        boundaryAndBoundaryPlaneFaceIdx = boundaryFaces(boundaryFacesIdx)
        boundaryFaceGlobalNo = boundaryAndBoundaryPlaneFaces(boundaryAndBoundaryPlaneFaceIdx)
      ELSE
        boundaryFaceGlobalNo = -1
      ENDIF

      IF (internalFacesIdx <= facesMapping%NUMBER_OF_INTERNAL) THEN
        internalFaceGlobalNo = internalFaces(internalFacesIdx)
      ELSE
        internalFaceGlobalNo = -1
      ENDIF

      IF ((internalFaceGlobalNo < boundaryFaceGlobalNo .AND. internalFaceGlobalNo /= -1) &
        & .OR. boundaryFaceGlobalNo == -1) THEN
        ! the next face is an internal face
        facesMapping%DOMAIN_LIST(domainListInternalIdx) = localFaceNo
        facesMapping%LOCAL_TO_GLOBAL_MAP(localFaceNo) = internalFaceGlobalNo
        domainListInternalIdx = domainListInternalIdx + 1
        internalFacesIdx = internalFacesIdx + 1

      ELSE
        ! the next face is a boundary face
        facesMapping%DOMAIN_LIST(domainListBoundaryIdx) = localFaceNo
        facesMapping%LOCAL_TO_GLOBAL_MAP(localFaceNo) = boundaryFaceGlobalNo
        domainListBoundaryIdx = domainListBoundaryIdx + 1
        boundaryFacesIdx = boundaryFacesIdx + 1


        ! update LOCAL_GHOST_SEND_INDICES

        ! loop over the domains where this face is present
        CALL LIST_NUMBER_OF_ITEMS_GET(domainsOfFaceList(boundaryAndBoundaryPlaneFaceIdx)%PTR, numberDomains, err,error,*999)
        DO I=1,numberDomains
          ! get domain no
          CALL LIST_ITEM_GET(domainsOfFaceList(boundaryAndBoundaryPlaneFaceIdx)%PTR,I,domainNo,err,error,*999)
          IF (domainNo /= myComputationalNodeNumber) THEN


            found=.FALSE.
            ! go to entry in ADJACENT_DOMAINS array for domainNo, at index adjacentDomainIdx
            DO adjacentDomainIdx =1,numberExtraAdjacentDomains
              IF (extraAdjacentDomains(adjacentDomainIdx) == domainNo) THEN
                found=.TRUE.


                EXIT
              ENDIF
            ENDDO
            IF(.NOT.found) THEN
              localError="Domain number "//TRIM(NumberToVString(domainNo,"*",err,error))// &
              & " was not found in the list of adjacent domains."
              CALL FlagError(localError,err,error,*999)
            ENDIF

            CALL LIST_ITEM_ADD(localGhostSendIndices(adjacentDomainIdx)%PTR,localFaceNo,err,error,*999)
          ENDIF
        ENDDO

        domainNo = boundaryAndBoundaryPlaneFacesDomain(boundaryAndBoundaryPlaneFaceIdx)

      ENDIF
      localFaceNo = localFaceNo + 1
    ENDDO

    domainListGhostIdx = facesMapping%GHOST_START
    ! loop over ghost faces
    DO ghostFaceIdx = 1,facesMapping%NUMBER_OF_GHOST
      ghostFaceGlobalNo = ghostFacesDomains(1,ghostFaceIdx)
      ghostDomain = ghostFacesDomains(2,ghostFaceIdx)

      facesMapping%DOMAIN_LIST(domainListGhostIdx) = localFaceNo
      facesMapping%LOCAL_TO_GLOBAL_MAP(domainListGhostIdx) = ghostFaceGlobalNo
      domainListGhostIdx = domainListGhostIdx + 1
      localFaceNo = localFaceNo + 1

      ! update LOCAL_GHOST_RECEIVE_INDICES


      ! find entry ADJACENT_DOMAINS array for domainNo
      adacentDomainEntryFound = .FALSE.
      DO adjacentDomainIdx=1,facesMapping%NUMBER_OF_ADJACENT_DOMAINS
        IF (facesMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%DOMAIN_NUMBER == ghostDomain) THEN


          CALL LIST_ITEM_ADD(localGhostReceiveIndices(adjacentDomainIdx)%PTR,localFaceNo-1,err,error,*999)

          adacentDomainEntryFound = .TRUE.
          EXIT
        ENDIF
      ENDDO ! adjacentDomainIdx

    ENDDO  ! ghostFaceIdx

    DO adjacentDomainIdx=1,numberExtraAdjacentDomains
      ! create localGhostSendIndices for the adjacent domain
      CALL LIST_DETACH_AND_DESTROY(localGhostSendIndices(adjacentDomainIdx)%PTR, &
        & facesMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%NUMBER_OF_SEND_GHOSTS,integerArray,err,error,*999)
      facesMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%LOCAL_GHOST_SEND_INDICES = &
        & integerArray(1:facesMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%NUMBER_OF_SEND_GHOSTS)
      IF(ALLOCATED(integerArray)) DEALLOCATE(integerArray)

      ! create localGhostReceiveIndices for the adjacent domain
      CALL LIST_DETACH_AND_DESTROY(localGhostReceiveIndices(adjacentDomainIdx)%PTR, &
        & facesMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%NUMBER_OF_RECEIVE_GHOSTS,integerArray,err,error,*999)
      facesMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%LOCAL_GHOST_RECEIVE_INDICES = &
        & integerArray(1:facesMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%NUMBER_OF_RECEIVE_GHOSTS)
      IF(ALLOCATED(integerArray)) DEALLOCATE(integerArray)

    ENDDO


    ! exchange NUMBER_OF_DOMAIN_LOCAL and NUMBER_OF_DOMAIN_GHOST
    ! allocate number_of_domain_local
    ALLOCATE(facesMapping%NUMBER_OF_DOMAIN_LOCAL(0:numberComputationalNodes-1),STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate NUMBER_OF_DOMAIN_LOCAL.",err,error,*999)

    facesMapping%NUMBER_OF_DOMAIN_LOCAL(myComputationalNodeNumber) = facesMapping%NUMBER_OF_LOCAL

    CALL MPI_ALLGATHER(MPI_IN_PLACE,1,MPI_INTEGER,facesMapping%&
      & NUMBER_OF_DOMAIN_LOCAL(0:numberComputationalNodes-1), &
      & 1,MPI_INTEGER,computationalEnvironment%mpiCommunicator,MPI_IERROR)
    CALL MPI_ERROR_CHECK("MPI_ALLGATHER",MPI_IERROR,err,error,*999)

    ! allocate number_of_domain_ghost
    ALLOCATE(facesMapping%NUMBER_OF_DOMAIN_GHOST(0:numberComputationalNodes-1),STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate NUMBER_OF_DOMAIN_GHOST.",err,error,*999)

    facesMapping%NUMBER_OF_DOMAIN_GHOST(myComputationalNodeNumber) = facesMapping%NUMBER_OF_GHOST

    CALL MPI_ALLGATHER(MPI_IN_PLACE,1,MPI_INTEGER,facesMapping%&
      & NUMBER_OF_DOMAIN_GHOST(0:numberComputationalNodes-1), &
      & 1,MPI_INTEGER,computationalEnvironment%mpiCommunicator,MPI_IERROR)
    CALL MPI_ERROR_CHECK("MPI_ALLGATHER",MPI_IERROR,err,error,*999)


    !The following ADJACENT_DOMAINS_PTR and ADJACENT_DOMAINS_LIST assignment will have to be done in a local way when everything is moved to local not global.

    !allocate and assign domainMappings%ADJACENT_DOMAIN_PTR and domainMappings%ADJACENT_DOMAIN_LIST
    !Currently for elements and nodes this is done in DOMAIN_MAPPINGS_LOCAL_FROM_GLOBAL_CALCULATE
    ALLOCATE(facesMapping%ADJACENT_DOMAINS_PTR(0:facesMapping%NUMBER_OF_DOMAINS),STAT=ERR)
    IF(ERR/=0) CALL FlagError("Could not allocate adjacent domains ptr.",ERR,ERROR,*999)
    facesMapping%ADJACENT_DOMAINS_PTR=elementsMapping%ADJACENT_DOMAINS_PTR

    ALLOCATE(facesMapping%ADJACENT_DOMAINS_LIST(facesMapping%ADJACENT_DOMAINS_PTR(facesMapping%NUMBER_OF_DOMAINS-1)),STAT=ERR)
    IF(ERR/=0) CALL FlagError("Could not allocate adjacent domains list.",ERR,ERROR,*999)
    facesMapping%ADJACENT_DOMAINS_LIST=elementsMapping%ADJACENT_DOMAINS_LIST



    ! deallocate arrays
    IF(ALLOCATED(boundaryAndBoundaryPlaneFaces)) DEALLOCATE(boundaryAndBoundaryPlaneFaces)
    IF(ALLOCATED(adjacentDomains)) DEALLOCATE(adjacentDomains)
    IF(ALLOCATED(sendRequestHandle)) DEALLOCATE(sendRequestHandle)
    IF(ALLOCATED(receiveRequestHandle)) DEALLOCATE(receiveRequestHandle)
    IF(ALLOCATED(numberNonBoundaryPlaneAndLocalFacesOnRank)) DEALLOCATE(numberNonBoundaryPlaneAndLocalFacesOnRank)
    IF(ALLOCATED(localAndAdjacentDomains)) DEALLOCATE(localAndAdjacentDomains)
    IF(ALLOCATED(boundaryAndBoundaryPlaneFacesDomain)) DEALLOCATE(boundaryAndBoundaryPlaneFacesDomain)
    IF(ALLOCATED(numberFacesInDomain)) DEALLOCATE(numberFacesInDomain)
    IF(ALLOCATED(internalFaces)) DEALLOCATE(internalFaces)
    IF(ALLOCATED(boundaryFaces)) DEALLOCATE(boundaryFaces)
    IF(ALLOCATED(sendRequestHandle0)) DEALLOCATE(sendRequestHandle0)
    IF(ALLOCATED(sendRequestHandle1)) DEALLOCATE(sendRequestHandle1)
    IF(ALLOCATED(ghostFacesDomains)) DEALLOCATE(ghostFacesDomains)
    IF(ALLOCATED(sendBuffer)) DEALLOCATE(sendBuffer)
    IF(ALLOCATED(numberToSendToDomain)) DEALLOCATE(numberToSendToDomain)
    IF(ALLOCATED(domainsOfFaceList)) DEALLOCATE(domainsOfFaceList)
    IF(ALLOCATED(faceOnBoundaryPlane)) DEALLOCATE(faceOnBoundaryPlane)
    IF(ALLOCATED(sharedFacesList)) DEALLOCATE(sharedFacesList)
    IF(ALLOCATED(extraAdjacentDomains)) DEALLOCATE(extraAdjacentDomains)
    IF(ALLOCATED(domainsOfBoundaryPlaneFaceList)) DEALLOCATE(domainsOfBoundaryPlaneFaceList)

    EXITS("DomainMappings_FacesCalculate")
    RETURN
    !FIXTHIS need to make sure I am deallocating the pointers that I assign in the subroutine.
  !998 IF(ALLOCATED(DOMAINS%MAPPINGS)) DEALLOCATE(Domains)
  !FIXTHIS Not sure if i need to deallocate facesMapping%ADJACENT_DOMAINS here
   !IF(ALLOCATED(facesMapping%ADJACENT_DOMAINS)) DEALLOCATE(facesMapping%ADJACENT_DOMAINS)
  999 IF(ASSOCIATED(domain%mesh%topology)) CALL DomainTopology_AssignGlobalFacesFinalise(domain,dummyErr,dummyError,*998)
      IF(ALLOCATED(boundaryAndBoundaryPlaneFaces)) DEALLOCATE(boundaryAndBoundaryPlaneFaces)
      IF(ALLOCATED(adjacentDomains)) DEALLOCATE(adjacentDomains)
      IF(ALLOCATED(sendRequestHandle)) DEALLOCATE(sendRequestHandle)
      IF(ALLOCATED(receiveRequestHandle)) DEALLOCATE(receiveRequestHandle)
      IF(ALLOCATED(numberNonBoundaryPlaneAndLocalFacesOnRank)) DEALLOCATE(numberNonBoundaryPlaneAndLocalFacesOnRank)
      IF(ALLOCATED(localAndAdjacentDomains)) DEALLOCATE(localAndAdjacentDomains)
      IF(ALLOCATED(boundaryAndBoundaryPlaneFacesDomain)) DEALLOCATE(boundaryAndBoundaryPlaneFacesDomain)
      IF(ALLOCATED(numberFacesInDomain)) DEALLOCATE(numberFacesInDomain)
      IF(ALLOCATED(internalFaces)) DEALLOCATE(internalFaces)
      IF(ALLOCATED(boundaryFaces)) DEALLOCATE(boundaryFaces)
      IF(ALLOCATED(sendRequestHandle0)) DEALLOCATE(sendRequestHandle0)
      IF(ALLOCATED(sendRequestHandle1)) DEALLOCATE(sendRequestHandle1)
      IF(ALLOCATED(ghostFacesDomains)) DEALLOCATE(ghostFacesDomains)
      IF(ALLOCATED(sendBuffer)) DEALLOCATE(sendBuffer)
      IF(ALLOCATED(numberToSendToDomain)) DEALLOCATE(numberToSendToDomain)
      IF(ALLOCATED(domainsOfFaceList)) DEALLOCATE(domainsOfFaceList)
      IF(ALLOCATED(faceOnBoundaryPlane)) DEALLOCATE(faceOnBoundaryPlane)
      IF(ALLOCATED(sharedFacesList)) DEALLOCATE(sharedFacesList)
      IF(ALLOCATED(extraAdjacentDomains)) DEALLOCATE(extraAdjacentDomains)
      IF(ALLOCATED(domainsOfBoundaryPlaneFaceList)) DEALLOCATE(domainsOfBoundaryPlaneFaceList)
  998 ERRORSEXITS("DomainMappings_FacesCalculate",err,error)
    RETURN 1
  END SUBROUTINE DomainMappings_FacesCalculate
  !
  !================================================================================================================================
  !

  !>Calculates the local/global 1D line mappings for a domain decomposition.
  SUBROUTINE DomainMappings_1DLinesCalculate(domain,err,error,*)

    !Argument variables
    TYPE(DOMAIN_TYPE), POINTER :: domain !<A pointer to the domain to calculate the Line dofs for.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: lineCount, elementGlobalNo,lineGlobalNo, componentIdx
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: elementsMapping
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: linesMapping
    TYPE(MESH_TYPE), POINTER :: mesh
    TYPE(MeshComponentTopologyType), POINTER :: topology
    TYPE(DECOMPOSITION_TYPE), POINTER :: decomposition


    ENTERS("DomainMappings_1DLinesCalculate",err,error,*999)

    IF(.NOT.ASSOCIATED(domain)) CALL FlagError("domain is not associated.",err,error,*999)
    IF(.NOT.ASSOCIATED(domain%MAPPINGS)) CALL FlagError("domain%MAPPINGS is not associated.",err,error,*999)
    linesMapping=>domain%MAPPINGS%LINES
    IF(.NOT.ASSOCIATED(domain%MAPPINGS%ELEMENTS)) CALL FlagError("domain%MAPPINGS%ELEMENTS is not associated.",err,error,*999)
    elementsMapping=>domain%MAPPINGS%ELEMENTS
    IF(.NOT.ASSOCIATED(domain%decomposition)) CALL FlagError("domain%decomposition is not associated.",err,error,*999)
    decomposition=>domain%decomposition
    IF(.NOT.ASSOCIATED(domain%mesh)) CALL FlagError("domain%mesh is not associated.",err,error,*999)
    mesh=>domain%mesh
    componentIdx=domain%MESH_COMPONENT_NUMBER
    topology=>mesh%topology(componentIdx)%PTR

    !For 1D lines mapping is exactly the same as elements mapping
    linesMapping=elementsMapping

    !>>.............. Topology equations should be in its own subroutine eventually



    CALL DomainTopology_AssignGlobalLinesInitialise(domain,err,error,*999)
    !\Todo should seperate the following into seperate subroutines
    !CALL DomainTopology_AssignGlobalLinesAndSurroundingElements(topology,err,error,*999)
    !CALL DomainTopology_AssignGlobalLines(topology,err,error,*999)
    !Assign global numbers to each line
    lineCount=0

    !FIXTHIS, change number order so that it is -2,2,-1,1
    DO elementGlobalNo = 1,topology%ELEMENTS%NUMBER_OF_ELEMENTS

      lineCount=lineCount+1
      topology%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_LINES(1)=lineCount

    ENDDO ! elementGlobalNo

    !FIXTHIS This dosn't neccesarily need to be using a type, could just use allocatable local arrays
    ALLOCATE(topology%lines)
    topology%lines%numberOfLines=lineCount
    ALLOCATE(topology%lines%lines(lineCount))


    !Iterate through the elements to assign them as neighbouring elements of the lines
    DO elementGlobalNo = 1,topology%ELEMENTS%NUMBER_OF_ELEMENTS

      lineGlobalNo=topology%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_LINES(1)

      ALLOCATE(topology%lines%lines(lineGlobalNo)%surroundingElements(1))

      topology%lines%lines(lineGlobalNo)%surroundingElements(1)=elementGlobalNo
      topology%lines%lines(lineGlobalNo)%globalNumber=lineGlobalNo
      topology%lines%lines(lineGlobalNo)%numberOfSurroundingElements=1
      topology%lines%lines(lineGlobalNo)%externalLine=.FALSE.

    ENDDO ! elementGlobalNo

    !<<.............. Topology equations should be in their own subroutine eventually



    EXITS("DomainMappings_1DLinesCalculate")
    RETURN
  999 ERRORSEXITS("DomainMappings_1DLinesCalculate",err,error)
    RETURN 1
  END SUBROUTINE DomainMappings_1DLinesCalculate

  !
  !================================================================================================================================
  !

  !>Calculates the local/global 2D line mappings for a domain decomposition.
  SUBROUTINE DomainMappings_2DLinesCalculate(domain,err,error,*)

    !Argument variables
    TYPE(DOMAIN_TYPE), POINTER :: domain !<A pointer to the domain to calculate the Line dofs for.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: myComputationalNodeNumber,numberComputationalNodes,componentIdx,numberBoundaryAndBoundaryPlaneLines, &
      & lineGlobalNo, lineCount, elementGlobalNo, elementLocalNo, startNic, xicIdx, elementIdx, xicIdx2, &
      & adjacentElementIdx, adjacentElementGlobalNo, adjacentElementLocalNo, I, J, adjacentElementGlobalNo2, &
      & arrayIndex, adjacentDomainIdx, domainNo, numberDomains, adjacentDomain, numberLocalAndAdjacentDomains, &
      & numberNonBoundaryPlaneAndLocalLines(2), numberLocalLines, numberAdjacentDomains, MPI_IERROR, numberSharedLines,  &
      & numberLinesWithThatSetOfDomains, sharedLineIdx2, boundaryAndBoundaryPlaneLineIdx2, domainToAssignLinesToIdx, sharedLineIdx,&
      & domainToAssignLinesTo, adjacentDomainIdx2, numberLocalLinesOnRank, numberNonBoundaryLinesOnRank, &
      & numberSharedLinesOnRank, numberInCurrentSetToClaim, ghostLineIdx, ghostLineGlobalNo, ghostDomain, &
      & domainIdx, domainNo2, maximumNumberToSend, numberToSend, numberOfLinesToReceive, internalLinesIdx, &
      & boundaryLinesIdx, localLineNo, domainListInternalIdx, domainListBoundaryIdx, internalLineGlobalNo, boundaryLineGlobalNo, &
      & domainListGhostIdx, dummyErr, numberBoundaryPlaneLines, domainNo3, lineIdx, &
      & boundaryAndBoundaryPlaneLineIdx, basisLocalLineIdx2, &
      & extraAdjacentDomain, numberExtraAdjacentDomains,nodeIdx, meshNodeNo, surroundingElemIdx, basisLocalLineIdx
    !
    INTEGER(INTG), ALLOCATABLE :: internalLines(:), integerArray(:), boundaryAndBoundaryPlaneLines(:), sendRequestHandle(:), &
      & numberNonBoundaryPlaneAndLocalLinesOnRank(:,:), receiveRequestHandle(:), boundaryAndBoundaryPlaneLinesDomain(:), &
      & numberLinesInDomain(:),adjacentDomains(:), localAndAdjacentDomains(:), boundaryLines(:), &
      & sendRequestHandle0(:), sendRequestHandle1(:), ghostLinesDomains(:,:), sendBuffer(:,:), numberToSendToDomain(:), &
      & receiveBuffer(:), lineOnBoundaryPlane(:), integerArray2D(:,:), extraAdjacentDomains(:), &
      & tempArray(:)
    TYPE(MESH_TYPE), POINTER :: mesh
    TYPE(MeshComponentTopologyType), POINTER :: topology
    TYPE(DECOMPOSITION_TYPE), POINTER :: decomposition
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: elementsMapping
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: linesMapping
    TYPE(LIST_TYPE), POINTER :: internalLinesList, boundaryAndBoundaryPlaneLinesList, adjacentDomainsList, &
      & localAndAdjacentDomainsList, boundaryLinesList, ghostLinesDomainsList,extraAdjacentDomainsList
    TYPE(LIST_PTR_TYPE), ALLOCATABLE :: domainsOfLineList(:), sharedLinesList(:), sendBufferList(:), localGhostSendIndices(:), &
       & localGhostReceiveIndices(:), domainsOfBoundaryPlaneLineList(:)
    REAL(DP) :: numberLines, optimalNumberLinesPerDomain, totalNumberLines, portionToDistribute, numberLinesAboveOptimum
    LOGICAL :: onOtherDomain,adacentDomainEntryFound, found
    TYPE(VARYING_STRING) :: dummyError, localError

    ENTERS("DomainMappings_2DLinesCalculate",err,error,*999)


    !FIXTHIS shouldn't be indented, we want something like this... IF(.NOT.ASSOCIATED(domain)) CALL FlagError("domain is not associated.",err,error,*999)
    !Also fix typecase on subroutine calls. And but allocate parts in DomainMappings_LinesInitialise subroutine
    IF(.NOT.ASSOCIATED(domain)) CALL FlagError("domain is not associated.",err,error,*999)
    IF(.NOT.ASSOCIATED(domain%MAPPINGS)) CALL FlagError("domain%MAPPINGS is not associated.",err,error,*999)
    linesMapping=>domain%MAPPINGS%LINES

    IF(.NOT.ASSOCIATED(domain%MAPPINGS%ELEMENTS)) CALL FlagError("domain%MAPPINGS%ELEMENTS is not associated.",err,error,*999)
    elementsMapping=>domain%MAPPINGS%ELEMENTS
    IF(.NOT.ASSOCIATED(domain%decomposition)) CALL FlagError("domain%decomposition is not associated.",err,error,*999)
    decomposition=>domain%decomposition
    IF(.NOT.ASSOCIATED(domain%mesh)) CALL FlagError("domain%mesh is not associated.",err,error,*999)
    mesh=>domain%mesh
    componentIdx=domain%MESH_COMPONENT_NUMBER
    topology=>mesh%topology(componentIdx)%PTR

    numberComputationalNodes=ComputationalEnvironment_NumberOfNodesGet(err,error)
    IF(err/=0) GOTO 999
    myComputationalNodeNumber=ComputationalEnvironment_NodeNumberGet(err,error)
    IF(err/=0) GOTO 999

    IF(DIAGNOSTICS1) THEN
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,&
        & "  numberComputationalNodes: ",numberComputationalNodes,err,error,*999)

    ENDIF


    ! create list for internal Lines
    NULLIFY(internalLinesList)
    CALL LIST_CREATE_START(internalLinesList,err,error,*999)
    CALL LIST_DATA_TYPE_SET(internalLinesList,LIST_INTG_TYPE,err,error,*999)
    CALL LIST_INITIAL_SIZE_SET(internalLinesList,elementsMapping%NUMBER_OF_LOCAL*2,err,error,*999)
    CALL LIST_CREATE_FINISH(internalLinesList,err,error,*999)


    !determine start Nic for basis directions, i.e quads have (-3,-2,-1,1,2,3), tets have (1,2,3,4)
    SELECT CASE(topology%ELEMENTS%ELEMENTS(1)%BASIS%TYPE)!Assumes all elements have the same basis
    CASE(BASIS_SIMPLEX_TYPE)
      startNic=1
    CASE(BASIS_LAGRANGE_HERMITE_TP_TYPE)
      startNic=-topology%ELEMENTS%ELEMENTS(1)%BASIS%NUMBER_OF_XI_COORDINATES
    CASE DEFAULT
      !do nothing
    END SELECT


!>>.............. Topology equations should be in its own subroutine eventually



    CALL DomainTopology_AssignGlobalLinesInitialise(domain,err,error,*999)
    !could seperate the following into seperate subroutines
    !CALL DomainTopology_AssignGlobalLinesAndSurroundingElements(topology,err,error,*999)
    !CALL DomainTopology_AssignGlobalLines(topology,err,error,*999)
    !Assign global numbers to each line
    lineCount=0

    !FIXTHIS, change number order so that it is -2,2,-1,1
    DO elementGlobalNo = 1,topology%ELEMENTS%NUMBER_OF_ELEMENTS
      DO basisLocalLineIdx = 1, topology%ELEMENTS%ELEMENTS(elementGlobalNo)%BASIS%NUMBER_OF_LOCAL_LINES
        xicIdx = topology%ELEMENTS%ELEMENTS(elementGlobalNo)%BASIS%localLineXiNormals(1,basisLocalLineIdx)
      ! DO xicIdx = startNic,topology%ELEMENTS%ELEMENTS(elementGlobalNo)%BASIS%NUMBER_OF_XI_COORDINATES
      !   IF(xicIdx ==0) CYCLE

        IF(topology%ELEMENTS%ELEMENTS(elementGlobalNo)%ADJACENT_ELEMENTS(xicIdx)%NUMBER_OF_ADJACENT_ELEMENTS==1) THEN
          adjacentElementGlobalNo=topology%ELEMENTS%ELEMENTS(elementGlobalNo)%ADJACENT_ELEMENTS(xicIdx)% &
            & ADJACENT_ELEMENTS(1)
          IF(adjacentElementGlobalNo>elementGlobalNo) THEN
            lineCount=lineCount+1
            topology%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_LINES(xicIdx)=lineCount

          ELSE
            DO basisLocalLineIdx2 = 1, topology%ELEMENTS%ELEMENTS(adjacentElementGlobalNo)%BASIS%NUMBER_OF_LOCAL_LINES
              xicIdx2 = topology%ELEMENTS%ELEMENTS(adjacentElementGlobalNo)%BASIS%localLineXiNormals(1,basisLocalLineIdx2)

              IF(topology%ELEMENTS%ELEMENTS(adjacentElementGlobalNo)%ADJACENT_ELEMENTS(xicIdx2)% &
                & NUMBER_OF_ADJACENT_ELEMENTS==1) THEN
                IF(topology%ELEMENTS%ELEMENTS(adjacentElementGlobalNo)%ADJACENT_ELEMENTS(xicIdx2)% &
                  & ADJACENT_ELEMENTS(1)==elementGlobalNo) THEN
                  topology%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_LINES(xicIdx)= &
                    & topology%ELEMENTS%ELEMENTS(adjacentElementGlobalNo)%GLOBAL_ELEMENT_LINES(xicIdx2)
                ENDIF
              ENDIF
            ENDDO
          ENDIF

        ELSE
          lineCount=lineCount+1
          topology%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_LINES(xicIdx)=lineCount
        ENDIF
      ENDDO ! basisLocalLineIdx
    ENDDO ! elementGlobalNo

    !FIXTHIS This dosn't neccesarily need to be using a type, could just use allocatable local arrays
    ALLOCATE(topology%lines)
    topology%lines%numberOfLines=lineCount
    ALLOCATE(topology%lines%lines(lineCount))


    !Iterate through the elements to allocate surrounding elements This should be done in an initialise subroutine
    DO lineGlobalNo = 1,topology%lines%numberOfLines

      ALLOCATE(topology%lines%lines(lineGlobalNo)%surroundingElements(2))
      topology%lines%lines(lineGlobalNo)%surroundingElements=-1
      topology%lines%lines(lineGlobalNo)%globalNumber=lineGlobalNo
      topology%lines%lines(lineGlobalNo)%numberOfSurroundingElements=0

    ENDDO


    !Iterate through the elements to assign them as neighbouring elements of the lines
    DO elementGlobalNo = 1,topology%ELEMENTS%NUMBER_OF_ELEMENTS
      !Iterate through the lines of this element
      DO basisLocalLineIdx = 1, topology%ELEMENTS%ELEMENTS(elementGlobalNo)%BASIS%NUMBER_OF_LOCAL_LINES
        xicIdx = topology%ELEMENTS%ELEMENTS(elementGlobalNo)%BASIS%localLineXiNormals(1,basisLocalLineIdx)

        lineGlobalNo=topology%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_LINES(xicIdx)



        IF(topology%lines%lines(lineGlobalNo)%surroundingElements(1)==-1) THEN
          topology%lines%lines(lineGlobalNo)%surroundingElements(1)=elementGlobalNo
        ELSE
          topology%lines%lines(lineGlobalNo)%surroundingElements(2)=elementGlobalNo
        ENDIF
        topology%lines%lines(lineGlobalNo)%numberOfSurroundingElements=topology%lines%lines(lineGlobalNo)% &
          & numberOfSurroundingElements+1
      ENDDO ! basisLocalLineIdx
    ENDDO ! elementGlobalNo

    DO lineGlobalNo = 1,topology%lines%numberOfLines

      IF(topology%lines%lines(lineGlobalNo)%numberOfSurroundingElements==1) THEN
        !The line is an external line
        topology%lines%lines(lineGlobalNo)%externalLine=.TRUE.
      ELSEIF(topology%lines%lines(lineGlobalNo)%numberOfSurroundingElements==2) THEN
        topology%lines%lines(lineGlobalNo)%externalLine=.FALSE.
      ELSE
        localError="A Line can only have 1 or 2 surrounding elements, not "//TRIM(NumberToVString( &
          & topology%lines%lines(lineGlobalNo)%numberOfSurroundingElements,"*",err,error))
        CALL FlagError(localError,err,error,*999)
      ENDIF

    ENDDO
!<<.............. Topology equations should be in their own subroutine eventually

    !allocate temporary array for the global numbers of the boundary elements
    ALLOCATE(tempArray(elementsMapping%NUMBER_OF_BOUNDARY))
    tempArray=elementsMapping%LOCAL_TO_GLOBAL_MAP(elementsMapping%DOMAIN_LIST(elementsMapping%BOUNDARY_START: &
      & elementsMapping%BOUNDARY_FINISH))

    ! determine interior Lines
    ! loop over interior elements
    DO elementIdx = elementsMapping%INTERNAL_START,elementsMapping%INTERNAL_FINISH
      elementLocalNo = elementsMapping%DOMAIN_LIST(elementIdx)
      elementGlobalNo = elementsMapping%LOCAL_TO_GLOBAL_MAP(elementLocalNo)

      ! loop over Lines of element
      DO basisLocalLineIdx = 1, topology%ELEMENTS%ELEMENTS(elementGlobalNo)%BASIS%NUMBER_OF_LOCAL_LINES
        xicIdx = topology%ELEMENTS%ELEMENTS(elementGlobalNo)%BASIS%localLineXiNormals(1,basisLocalLineIdx)

        lineGlobalNo=topology%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_LINES(xicIdx)


        onOtherDomain = .FALSE.


        ! determine if any of this lines adjacent elements are boundary elements, that is the case if it is a boundary line.
        DO adjacentElementIdx=1,topology%lines%lines(lineGlobalNo)%numberOfSurroundingElements
          adjacentElementGlobalNo=topology%lines%lines(lineGlobalNo)%surroundingElements(adjacentElementIdx)

          !tempArray holds the global element numbers of the boundary elements of this rank
          IF (SORTED_ARRAY_CONTAINS_ELEMENT(tempArray,adjacentElementGlobalNo,err,error)) THEN

            onOtherDomain = .TRUE.
            EXIT
          ENDIF

        ENDDO

        !If line is not a boundary line it is an interal line.
        IF (.NOT. onOtherDomain) THEN
          ! add Line to internal Line list
          CALL LIST_ITEM_ADD(internalLinesList, lineGlobalNo,err,error,*999)
        ENDIF
      ENDDO
    ENDDO

    IF(ALLOCATED(tempArray)) DEALLOCATE(tempArray)


    ! sort list by global line number store number of internal lines in lineMapping
    CALL LIST_REMOVE_DUPLICATES(internalLinesList,err,error,*999)
    CALL LIST_DETACH_AND_DESTROY(internalLinesList,linesMapping%NUMBER_OF_INTERNAL,&
    & integerArray,err,error,*999)
    ALLOCATE(internalLines(linesMapping%NUMBER_OF_INTERNAL))
    internalLines=integerArray(1:linesMapping%NUMBER_OF_INTERNAL)

    IF(ALLOCATED(integerArray)) DEALLOCATE(integerArray)



    IF (DIAGNOSTICS1) THEN
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,&
        & "number internal lines: ",linesMapping%NUMBER_OF_INTERNAL,err,error,*999)
      DO I=1,linesMapping%NUMBER_OF_INTERNAL
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  global line no. ", &
          & internalLines(I),err,error,*999)
      ENDDO
    ENDIF


    ! create list for boundary and boundary plane lines (global line numbers)
    NULLIFY(boundaryAndBoundaryPlaneLinesList)
    CALL LIST_CREATE_START(boundaryAndBoundaryPlaneLinesList,err,error,*999)
    CALL LIST_DATA_TYPE_SET(boundaryAndBoundaryPlaneLinesList,LIST_INTG_TYPE,err,error,*999)
    CALL LIST_INITIAL_SIZE_SET(boundaryAndBoundaryPlaneLinesList,elementsMapping%NUMBER_OF_LOCAL,err,error,*999)
    CALL LIST_CREATE_FINISH(boundaryAndBoundaryPlaneLinesList,err,error,*999)

    ! loop over boundary elements
    DO elementIdx = elementsMapping%BOUNDARY_START,elementsMapping%BOUNDARY_FINISH
      elementLocalNo = elementsMapping%DOMAIN_LIST(elementIdx)
      elementGlobalNo = elementsMapping%LOCAL_TO_GLOBAL_MAP(elementLocalNo)

      ! loop over Lines of element
      DO basisLocalLineIdx = 1, topology%ELEMENTS%ELEMENTS(elementGlobalNo)%BASIS%NUMBER_OF_LOCAL_LINES
        xicIdx = topology%ELEMENTS%ELEMENTS(elementGlobalNo)%BASIS%localLineXiNormals(1,basisLocalLineIdx)
        lineGlobalNo=topology%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_LINES(xicIdx)

        ! if global line is not contained in internal lines list
        IF (.NOT. SORTED_ARRAY_CONTAINS_ELEMENT(internalLines,lineGlobalNo,err,error)) THEN

          ! Add line to boundary lines list (Important! This is called boundaryAndBoundaryPlaneLines because it contains all the boundary &
          ! & boundary plane lines, even though some of the boundary plane lines will be ghost lines).
          IF(elementIdx<=elementsMapping%BOUNDARY_FINISH) THEN
            CALL LIST_ITEM_ADD(boundaryAndBoundaryPlaneLinesList,lineGlobalNo,err,error,*999)
          ENDIF
        ELSE
          localError="global line number  "//TRIM(NumberToVString(lineGlobalNo,"*",err,error))// &
          & " is contained in internal lines when it should be a boundary line."
          CALL FlagError(localError,err,error,*999)
        ENDIF
      ENDDO
    ENDDO

    ! Sort list by global line number and remove duplicates
    CALL LIST_REMOVE_DUPLICATES(boundaryAndBoundaryPlaneLinesList,err,error,*999)

    ! count number of lines that lie on boundary and boundary plane and are shared with other domains
    CALL LIST_DETACH_AND_DESTROY(boundaryAndBoundaryPlaneLinesList,numberBoundaryAndBoundaryPlaneLines,integerArray,&
      & err,error,*999)
    ALLOCATE(boundaryAndBoundaryPlaneLines(numberBoundaryAndBoundaryPlaneLines))
    boundaryAndBoundaryPlaneLines = integerArray(1:numberBoundaryAndBoundaryPlaneLines)

    IF(ALLOCATED(integerArray)) DEALLOCATE(integerArray)

    !Allocate the array who's index will be 1 if that index of boundaryAndBoundaryPlaneLines is on the boundary plane
    ALLOCATE(lineOnBoundaryPlane(numberBoundaryAndBoundaryPlaneLines))
    lineOnBoundaryPlane=-1


    ! allocate lists of foreign domains in which boundary lines are present=. These will be the domains that have the relevant line as a ghost or boundary
    ALLOCATE(domainsOfLineList(numberBoundaryAndBoundaryPlaneLines),STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate domain list.",err,error,*999)

    ! allocate lists of foreign domains that share a boundary plane with the boundary line
    ALLOCATE(domainsOfBoundaryPlaneLineList(numberBoundaryAndBoundaryPlaneLines),STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate domain list.",err,error,*999)

    DO I=1, numberBoundaryAndBoundaryPlaneLines
      NULLIFY(domainsOfBoundaryPlaneLineList(I)%PTR)
      CALL LIST_CREATE_START(domainsOfBoundaryPlaneLineList(I)%PTR,err,error,*999)
      CALL LIST_DATA_TYPE_SET(domainsOfBoundaryPlaneLineList(I)%PTR,LIST_INTG_TYPE,err,error,*999)
      CALL LIST_INITIAL_SIZE_SET(domainsOfBoundaryPlaneLineList(I)%PTR,elementsMapping%NUMBER_OF_ADJACENT_DOMAINS+1,err,error,*999)
      CALL LIST_CREATE_FINISH(domainsOfBoundaryPlaneLineList(I)%PTR,err,error,*999)
    ENDDO

    DO I=1, numberBoundaryAndBoundaryPlaneLines
      NULLIFY(domainsOfLineList(I)%PTR)
      CALL LIST_CREATE_START(domainsOfLineList(I)%PTR,err,error,*999)
      CALL LIST_DATA_TYPE_SET(domainsOfLineList(I)%PTR,LIST_INTG_TYPE,err,error,*999)
      CALL LIST_INITIAL_SIZE_SET(domainsOfLineList(I)%PTR,elementsMapping%NUMBER_OF_ADJACENT_DOMAINS+1,err,error,*999)
      CALL LIST_CREATE_FINISH(domainsOfLineList(I)%PTR,err,error,*999)
    ENDDO


    !Counter for number of lines on the boundary plane
    numberBoundaryPlaneLines=0

    ! fill domainsOfBoundaryPlaneLineList with all foreign domains for each boundary plane line
    ! domainsOf BoundaryPlaneLineList only includes the domains which are physically on the boundary plane

    !Allocate temporary array for global numbers of ghost elements
    ALLOCATE(tempArray(elementsMapping%NUMBER_OF_GHOST))
    tempArray=elementsMapping%LOCAL_TO_GLOBAL_MAP(elementsMapping%DOMAIN_LIST(elementsMapping%GHOST_START: &
      & elementsMapping%GHOST_FINISH))

    ! loop over boundary and boundary plane indices
    DO boundaryAndBoundaryPlaneLineIdx=1,numberBoundaryAndBoundaryPlaneLines
      lineGlobalNo=boundaryAndBoundaryPlaneLines(boundaryAndBoundaryPlaneLineIdx)

      ! loop over adjacent elements of this line
      DO adjacentElementIdx=1,topology%lines%lines(lineGlobalNo)%numberOfSurroundingElements
        adjacentElementGlobalNo=topology%lines%lines(lineGlobalNo)%surroundingElements(adjacentElementIdx)


        ! if adjacent element is among the ghost elements, i.e is also on another domain. The tempArray has the global numbers
        ! of the ghost elements from ghost start in index 1 to ghost finish in the final index, therefore we can get the element idx from the index in the array.
        IF (SORTED_ARRAY_CONTAINS_ELEMENT_INDEX(tempArray,adjacentElementGlobalNo,arrayIndex, &
          & err,error)) THEN

          adjacentElementLocalNo = elementsMapping%DOMAIN_LIST(elementsMapping%GHOST_START + arrayIndex-1)

          ! determine domain of adjacentElementLocalNo
          DO adjacentDomainIdx=1,elementsMapping%NUMBER_OF_ADJACENT_DOMAINS
            IF (SORTED_ARRAY_CONTAINS_ELEMENT(elementsMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%&
              & LOCAL_GHOST_RECEIVE_INDICES,adjacentElementLocalNo,err,error)) THEN

              domainNo = elementsMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%DOMAIN_NUMBER

              ! now it was found that lineGlobalNo is also on the boundary plane of domain domainNo, add to list
              CALL LIST_ITEM_ADD(domainsOfBoundaryPlaneLineList(boundaryAndBoundaryPlaneLineIdx)%PTR,domainNo,err,error,*999)

              lineOnBoundaryPlane(boundaryAndBoundaryPlaneLineIdx)=1
              numberBoundaryPlaneLines=numberBoundaryPlaneLines+1

              !now check if any of the adjacent elements to this adjacent element is on another domain.
              !If it is add it to the domainsOfLineList for this lines index, the rest of domainsOfLineList gets assigned in the following section
              DO nodeIdx = 1,topology%ELEMENTS%ELEMENTS(adjacentElementGlobalNo)%BASIS%NUMBER_OF_NODES !Fix this, atm iterating through nodes then surrounding elems of those nodes is the only way to find surrounding elems (including diagonal elems)
                meshNodeNo=topology%ELEMENTS%ELEMENTS(adjacentElementGlobalNo)%MESH_ELEMENT_NODES(nodeIdx)
                DO surroundingElemIdx = 1,topology%NODES%NODES(meshNodeNo)%numberOfSurroundingElements
                  adjacentElementGlobalNo2 = topology%NODES%NODES(meshNodeNo)%surroundingElements(surroundingElemIdx)

                  domainNo2=decomposition%ELEMENT_DOMAIN(adjacentElementGlobalNo2) !Unsure if decomposition should be used here. If so, can use decomposition more in this subroutine.

                  IF(domainNo2/=domainNo .AND. domainNo2/=myComputationalNodeNumber) THEN

                    CALL LIST_ITEM_ADD(domainsOfLineList(boundaryAndBoundaryPlaneLineIdx)%PTR,domainNo2,err,error,*999)
                  ENDIF
                ENDDO !surroundingElemIdx
              ENDDO !nodeIdx
            ENDIF
          ENDDO  ! adjacentDomainIdx
        ENDIF
      ENDDO  ! adjacentElementIdx
    ENDDO  ! boundaryAndBoundaryPlaneLineIdx

    IF(ALLOCATED(tempArray)) DEALLOCATE(tempArray)



    ALLOCATE(tempArray(elementsMapping%NUMBER_OF_BOUNDARY))
    tempArray=elementsMapping%LOCAL_TO_GLOBAL_MAP(elementsMapping%DOMAIN_LIST(elementsMapping%BOUNDARY_START: &
      & elementsMapping%BOUNDARY_FINISH))

    ! loop over boundary and boundary plane indices and assign to each line the domains that have it as a ghost or boundary plane
    DO boundaryAndBoundaryPlaneLineIdx=1,numberBoundaryAndBoundaryPlaneLines
      lineGlobalNo=boundaryAndBoundaryPlaneLines(boundaryAndBoundaryPlaneLineIdx)

      ! loop over adjacent elements of this line
      DO adjacentElementIdx=1,topology%lines%lines(lineGlobalNo)%numberOfSurroundingElements
        adjacentElementGlobalNo=topology%lines%lines(lineGlobalNo)%surroundingElements(adjacentElementIdx)


        ! if adjacent element is among the boundary or ghost elements, i.e is also on another domain. The tempArray has the global numbers
        ! of the boundary elements from boundary start in index 1 to boundary finish in the final index, therefore we can get the element idx from the index in the array.
        IF (SORTED_ARRAY_CONTAINS_ELEMENT_INDEX(tempArray,adjacentElementGlobalNo,arrayIndex, &
          & err,error)) THEN

          adjacentElementLocalNo = elementsMapping%DOMAIN_LIST(elementsMapping%BOUNDARY_START + arrayIndex-1)

          ! determine domain of adjacentElementLocalNo
          DO adjacentDomainIdx=1,elementsMapping%NUMBER_OF_ADJACENT_DOMAINS

            domainNo = elementsMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%DOMAIN_NUMBER

            IF (SORTED_ARRAY_CONTAINS_ELEMENT(elementsMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%&
              & LOCAL_GHOST_SEND_INDICES,adjacentElementLocalNo,err,error)) THEN

              ! now it was found that lineGlobalNo is also on domain domainNo, add to list
              CALL LIST_ITEM_ADD(domainsOfLineList(boundaryAndBoundaryPlaneLineIdx)%PTR,domainNo,err,error,*999)
            ENDIF
          ENDDO  ! adjacentDomainIdxDomainMappings_LinesCalculate
        ENDIF


      ENDDO  ! adjacentElementIdx
    ENDDO  ! boundaryAndBoundaryPlaneLineIdx

    IF(ALLOCATED(tempArray)) DEALLOCATE(tempArray)




    !AdjacentDomainsList holds the domains that share a boundary plane (If the domain only shares a boundary plane node, but not a line it is not in adjacentDomainsList )
    NULLIFY(adjacentDomainsList)
    CALL LIST_CREATE_START(adjacentDomainsList,err,error,*999)
    CALL LIST_DATA_TYPE_SET(adjacentDomainsList,LIST_INTG_TYPE,err,error,*999)
    CALL LIST_CREATE_FINISH(adjacentDomainsList,err,error,*999)

    !extraAdjeacent Domains holds the domains which share ghost/boundary elements with the current domain
    NULLIFY(extraAdjacentDomainsList)
    CALL LIST_CREATE_START(extraAdjacentDomainsList,err,error,*999)
    CALL LIST_DATA_TYPE_SET(extraAdjacentDomainsList,LIST_INTG_TYPE,err,error,*999)
    CALL LIST_CREATE_FINISH(extraAdjacentDomainsList,err,error,*999)

    ! remove duplicate entries for the domains for the lines
    DO I=1, numberBoundaryAndBoundaryPlaneLines
      CALL LIST_REMOVE_DUPLICATES(domainsOfBoundaryPlaneLineList(I)%PTR,err,error,*999)
      CALL LIST_REMOVE_DUPLICATES(domainsOfLineList(I)%PTR,err,error,*999)

      ! add adjacent domains to adjacentDomainsList
      CALL LIST_NUMBER_OF_ITEMS_GET(domainsOfBoundaryPlaneLineList(I)%PTR,numberDomains,err,error,*999)
      DO J=1,numberDomains
        CALL LIST_ITEM_GET(domainsOfBoundaryPlaneLineList(I)%PTR,J,adjacentDomain,err,error,*999)
        CALL LIST_ITEM_ADD(adjacentDomainsList,adjacentDomain,err,error,*999)
      ENDDO

      ! add adjacent domains to extraAdjacentDomainsList
      CALL LIST_NUMBER_OF_ITEMS_GET(domainsOfLineList(I)%PTR,numberDomains,err,error,*999)
      DO J=1,numberDomains
        CALL LIST_ITEM_GET(domainsOfLineList(I)%PTR,J,extraAdjacentDomain,err,error,*999)
        CALL LIST_ITEM_ADD(extraAdjacentDomainsList,extraAdjacentDomain,err,error,*999)
      ENDDO
    ENDDO

    ! determine distinct list of adjacent domains
    CALL LIST_REMOVE_DUPLICATES(adjacentDomainsList,err,error,*999)
    CALL LIST_REMOVE_DUPLICATES(extraAdjacentDomainsList,err,error,*999)

    ! create sorted list that contains local domain and all adjacent domains that share a boundary plane
    NULLIFY(localAndAdjacentDomainsList)
    CALL LIST_CREATE_START(localAndAdjacentDomainsList,err,error,*999)
    CALL LIST_DATA_TYPE_SET(localAndAdjacentDomainsList,LIST_INTG_TYPE,err,error,*999)
    CALL LIST_CREATE_FINISH(localAndAdjacentDomainsList,err,error,*999)
    CALL LIST_ITEM_ADD(localAndAdjacentDomainsList,myComputationalNodeNumber,err,error,*999)
    CALL LIST_APPENDLIST(localAndAdjacentDomainsList,adjacentDomainsList,err,error,*999)
    CALL LIST_SORT(localAndAdjacentDomainsList,err,error,*999)

    !numberAdjacentDomains is the number of domains that share a boundary plane line with the local domain
    CALL LIST_DETACH_AND_DESTROY(adjacentDomainsList,numberAdjacentDomains,integerArray,err,error,*999)
    ALLOCATE(adjacentDomains(numberAdjacentDomains))
    adjacentDomains = integerArray(1:numberAdjacentDomains)
    IF(ALLOCATED(integerArray)) DEALLOCATE(integerArray)

    !numberExtraAdjacentDomains is the number of domains that will share ghost/boundary lines with the local domain
    CALL LIST_DETACH_AND_DESTROY(extraAdjacentDomainsList,numberExtraAdjacentDomains,integerArray,err,error,*999)
    ALLOCATE(extraAdjacentDomains(numberExtraAdjacentDomains))
    extraAdjacentDomains = integerArray(1:numberExtraAdjacentDomains)
    IF(ALLOCATED(integerArray)) DEALLOCATE(integerArray)

    !numberLocalAndAdjacentDomains equals numberAdjacentDomains + 1, adding one for the local domain
    CALL LIST_DETACH_AND_DESTROY(localAndAdjacentDomainsList,numberLocalAndAdjacentDomains,integerArray,&
      & err,error,*999)
    ALLOCATE(localAndAdjacentDomains(numberLocalAndAdjacentDomains))
    localAndAdjacentDomains = integerArray(1:numberLocalAndAdjacentDomains)
    IF(ALLOCATED(integerArray)) DEALLOCATE(integerArray)

    ! create list for each adjacent domain with shared lines at the boundary plane
    ALLOCATE(sharedLinesList(numberAdjacentDomains),STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate shared lines list.",err,error,*999)

    DO adjacentDomainIdx=1,numberAdjacentDomains
      NULLIFY(sharedLinesList(adjacentDomainIdx)%PTR)
      CALL LIST_CREATE_START(sharedLinesList(adjacentDomainIdx)%PTR,err,error,*999)
      CALL LIST_DATA_TYPE_SET(sharedLinesList(adjacentDomainIdx)%PTR,LIST_INTG_TYPE,err,error,*999)
      CALL LIST_CREATE_FINISH(sharedLinesList(adjacentDomainIdx)%PTR,err,error,*999)
    ENDDO

    ! fill sharedLinesList
    DO I=1,numberBoundaryAndBoundaryPlaneLines

      ! loop over adjacent domains of line I
      CALL LIST_NUMBER_OF_ITEMS_GET(domainsOfBoundaryPlaneLineList(I)%PTR,numberDomains,err,error,*999)
      DO J=1,numberDomains
        CALL LIST_ITEM_GET(domainsOfBoundaryPlaneLineList(I)%PTR,J,adjacentDomain,err,error,*999)

        ! get index of sharedLinesList
        IF (SORTED_ARRAY_CONTAINS_ELEMENT_INDEX(adjacentDomains,&
          & adjacentDomain,adjacentDomainIdx,err,error)) THEN

          ! add line to sharedLineslist of domain adjacentDomainIdx
          CALL LIST_ITEM_ADD(sharedLinesList(adjacentDomainIdx)%PTR,I,err,error,*999)
        ENDIF
      ENDDO
    ENDDO


    ! determine total number of lines on all ranks

    ! count number of lines where boundary plane lines are counted as the resp. fraction such that the sum is 1 for all processes
    numberLines = REAL(linesMapping%NUMBER_OF_INTERNAL,DP)

    DO I=1,numberBoundaryAndBoundaryPlaneLines
      IF(lineOnBoundaryPlane(I)==1) THEN
        CALL LIST_NUMBER_OF_ITEMS_GET(domainsOfBoundaryPlaneLineList(I)%PTR,numberDomains,err,error,*999)
        numberLines = numberLines + 1.0_DP/(REAL(numberDomains,DP)+1.0_DP)
      ELSE
        numberLines = numberLines + 1.0_DP
      ENDIF
    ENDDO

    ! allreduce number of lines
    CALL MPI_ALLREDUCE(numberLines,totalNumberLines,1,MPI_DOUBLE,MPI_SUM, &
      & computationalEnvironment%mpiCommunicator,MPI_IERROR)
    CALL MPI_ERROR_CHECK("MPI_ALLREDUCE",MPI_IERROR,err,error,*999)
    linesMapping%NUMBER_OF_GLOBAL = NINT(totalNumberLines)


    ! compute average number per domain
    linesMapping%NUMBER_OF_DOMAINS = elementsMapping%NUMBER_OF_DOMAINS
    optimalNumberLinesPerDomain = REAL(linesMapping%NUMBER_OF_GLOBAL,DP) / linesMapping%NUMBER_OF_DOMAINS

    ! exchange number of local lines among adjacent ranks
    numberLocalLines = linesMapping%NUMBER_OF_INTERNAL + numberBoundaryAndBoundaryPlaneLines
    !First entry is the number of local lines, not including boundary plane or ghost lines
    !Second entry is the number of local lines, including the boundary plane but not ghosts
    numberNonBoundaryPlaneAndLocalLines(1) = numberLocalLines-numberBoundaryPlaneLines
    numberNonBoundaryPlaneAndLocalLines(2) = numberLocalLines

    ! allocate request handles
    ALLOCATE(sendRequestHandle(numberLocalAndAdjacentDomains), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate sendRequestHandle array with size "//&
      & TRIM(NUMBER_TO_VSTRING(numberAdjacentDomains+1,"*",err,error))//".",err,error,*999)

    ALLOCATE(receiveRequestHandle(numberLocalAndAdjacentDomains), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate receiveRequestHandle array with size "//&
      & TRIM(NUMBER_TO_VSTRING(numberLocalAndAdjacentDomains,"*",err,error))//".",err,error,*999)

    ! allocate receive buffer (2 entries for interior and totally stored local lines, adjacent domains + local domain)
    ALLOCATE(numberNonBoundaryPlaneAndLocalLinesOnRank(2,numberAdjacentDomains+1), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate numberNonBoundaryPlaneAndLocalLinesOnRank array with size "//&
      & TRIM(NUMBER_TO_VSTRING(2*(numberLocalAndAdjacentDomains),"*",err,error))//".",err,error,*999)

    ! commit send commands
    DO adjacentDomainIdx=1,numberLocalAndAdjacentDomains
      adjacentDomain = localAndAdjacentDomains(adjacentDomainIdx)

      CALL MPI_ISEND(numberNonBoundaryPlaneAndLocalLines, 2, MPI_INT, adjacentDomain, 0, &
        & computationalEnvironment%mpiCommunicator, sendRequestHandle(adjacentDomainIdx), MPI_IERROR)
      CALL MPI_ERROR_CHECK("MPI_ISEND",MPI_IERROR,err,error,*999)
    ENDDO

    ! commit receive commands
    DO adjacentDomainIdx=1,numberLocalAndAdjacentDomains
      adjacentDomain = localAndAdjacentDomains(adjacentDomainIdx)
      CALL MPI_IRECV(numberNonBoundaryPlaneAndLocalLinesOnRank(:,adjacentDomainIdx), 2, MPI_INT, adjacentDomain, 0, &
        & computationalEnvironment%mpiCommunicator, receiveRequestHandle(adjacentDomainIdx), MPI_IERROR)
      CALL MPI_ERROR_CHECK("MPI_IRECV",MPI_IERROR,err,error,*999)
    ENDDO

    ! wait for all communication to finish
    CALL MPI_WAITALL(numberLocalAndAdjacentDomains, sendRequestHandle, MPI_STATUSES_IGNORE, MPI_IERROR)
    CALL MPI_ERROR_CHECK("MPI_WAITALL",MPI_IERROR,err,error,*999)

    CALL MPI_WAITALL(numberLocalAndAdjacentDomains, receiveRequestHandle, MPI_STATUSES_IGNORE, MPI_IERROR)
    CALL MPI_ERROR_CHECK("MPI_WAITALL",MPI_IERROR,err,error,*999)

    ! assign boundary lines to domains
    ! allocate boundaryAndBoundaryPlaneLinesDomain
    ALLOCATE(boundaryAndBoundaryPlaneLinesDomain(numberBoundaryAndBoundaryPlaneLines), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate boundaryAndBoundaryPlaneLinesDomain array with size "//&
      & TRIM(NUMBER_TO_VSTRING(numberBoundaryAndBoundaryPlaneLines,"*",err,error))//".",err,error,*999)
    boundaryAndBoundaryPlaneLinesDomain = -1

    ALLOCATE(numberLinesInDomain(numberLocalAndAdjacentDomains), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate numberLinesInDomain array with size "//&
      & TRIM(NUMBER_TO_VSTRING(numberLocalAndAdjacentDomains,"*",err,error))//".",err,error,*999)
    numberLinesInDomain = 0



    ! add local domain to domain list of each line
    DO boundaryAndBoundaryPlaneLineIdx=1,numberBoundaryAndBoundaryPlaneLines
      CALL LIST_ITEM_ADD(domainsOfBoundaryPlaneLineList(boundaryAndBoundaryPlaneLineIdx)%PTR, &
        & myComputationalNodeNumber,err,error,*999)
      CALL LIST_SORT(domainsOfBoundaryPlaneLineList(boundaryAndBoundaryPlaneLineIdx)%PTR,err,error,*999)
      !Assign local domain to the boundary lines that are not on the boundary plane
      IF(lineOnBoundaryPlane(boundaryAndBoundaryPlaneLineIdx) == -1) THEN
        boundaryAndBoundaryPlaneLinesDomain(boundaryAndBoundaryPlaneLineIdx) = myComputationalNodeNumber
      ENDIF
    ENDDO

    ! add local domain to domain list of each line
    DO boundaryAndBoundaryPlaneLineIdx=1,numberBoundaryAndBoundaryPlaneLines
      CALL LIST_ITEM_ADD(domainsOfLineList(boundaryAndBoundaryPlaneLineIdx)%PTR,myComputationalNodeNumber,err,error,*999)
      CALL LIST_SORT(domainsOfLineList(boundaryAndBoundaryPlaneLineIdx)%PTR,err,error,*999)
    ENDDO


    ! loop over adjacent domains
    DO adjacentDomainIdx=1,numberAdjacentDomains
      adjacentDomain = adjacentDomains(adjacentDomainIdx)


      ! loop over adjacent lines on that adjacent domain
      CALL LIST_NUMBER_OF_ITEMS_GET(sharedLinesList(adjacentDomainIdx)%PTR,numberSharedLines,err,error,*999)
      DO sharedLineIdx = 1,numberSharedLines
        CALL LIST_ITEM_GET(sharedLinesList(adjacentDomainIdx)%PTR,sharedLineIdx,boundaryAndBoundaryPlaneLineIdx,&
          & err,error,*999)



        ! if line was not yet assigned to a domain (This array was initialised earlier in the subroutine to be -1)
        IF (boundaryAndBoundaryPlaneLinesDomain(boundaryAndBoundaryPlaneLineIdx) == -1) THEN
          ! note: this line is shared by the domains in domainsOfBoundaryPlaneLineList(boundaryAndBoundaryPlaneLineIdx) (includes local domain)

          numberLinesWithThatSetOfDomains = 0

          ! loop over all further lines to find other lines that are shared by the same domains, count total number of them
          DO sharedLineIdx2 = sharedLineIdx,numberSharedLines
            CALL LIST_ITEM_GET(sharedLinesList(adjacentDomainIdx)%PTR,sharedLineIdx2,boundaryAndBoundaryPlaneLineIdx2,&
              & err,error,*999)

            IF (boundaryAndBoundaryPlaneLinesDomain(boundaryAndBoundaryPlaneLineIdx2) == -1) THEN

              !if the domain list of each boundary line is equal then add 1 to the number of lines with that set of domains.
              IF (LIST_EQUAL(domainsOfBoundaryPlaneLineList(boundaryAndBoundaryPlaneLineIdx)%PTR, &
                & domainsOfBoundaryPlaneLineList(boundaryAndBoundaryPlaneLineIdx2)%PTR,err,error)) THEN

                numberLinesWithThatSetOfDomains = numberLinesWithThatSetOfDomains+1
              ENDIF
            ENDIF
          ENDDO

          ! get first of the shared domains
          numberLinesInDomain = 0
          domainToAssignLinesToIdx = 1
          CALL LIST_ITEM_GET(domainsOfBoundaryPlaneLineList(boundaryAndBoundaryPlaneLineIdx)%PTR,domainToAssignLinesToIdx, &
            & domainToAssignLinesTo,err,error,*999)
          CALL LIST_NUMBER_OF_ITEMS_GET(domainsOfBoundaryPlaneLineList(boundaryAndBoundaryPlaneLineIdx)%PTR, &
            & numberDomains,err,error,*999)

          ! again loop over all further lines with the same domains, assign them to domains
          DO sharedLineIdx2 = sharedLineIdx,numberSharedLines
            CALL LIST_ITEM_GET(sharedLinesList(adjacentDomainIdx)%PTR,sharedLineIdx2,boundaryAndBoundaryPlaneLineIdx2,&
                & err,error,*999)

            !if the domain list of each boundary line is equal
            IF(LIST_EQUAL(domainsOfBoundaryPlaneLineList(boundaryAndBoundaryPlaneLineIdx)%PTR, &
              & domainsOfBoundaryPlaneLineList(boundaryAndBoundaryPlaneLineIdx2)%PTR,err,error)) THEN


              !FIXTHIS should iterate DO domainToAssignLinesToIdx = 1,2 for lines, leave as is for now so it is more similar to what it should be for nodes.
              DO

                ! find index for numberNonBoundaryPlaneAndLocalLinesOnRank that corresponds to domain domainToAssignLinesTo
                adjacentDomainIdx2 = 1
                DO I=1,numberLocalAndAdjacentDomains
                  adjacentDomain = localAndAdjacentDomains(I)
                  IF (adjacentDomain == domainToAssignLinesTo) THEN
                    adjacentDomainIdx2 = I
                    EXIT
                  ENDIF
                ENDDO

                ! compute the number of lines that this domain will get from the current set of lines
                numberLocalLinesOnRank = numberNonBoundaryPlaneAndLocalLinesOnRank(2,adjacentDomainIdx2)
                numberNonBoundaryLinesOnRank = numberNonBoundaryPlaneAndLocalLinesOnRank(1,adjacentDomainIdx2)

                numberLinesAboveOptimum = numberLocalLinesOnRank - optimalNumberLinesPerDomain
                numberSharedLinesOnRank = numberLocalLinesOnRank - numberNonBoundaryLinesOnRank

                ! compute the portion of each line that adjacent domain should get from other domains
                ! E.g. if portionToDistribute=0.4 that means that 4 out of 10 shared lines of the adjacent domain should be assigned to other domains and 6 should remain their own
                portionToDistribute = numberLinesAboveOptimum / numberSharedLinesOnRank

                ! compute the number of lines from the current set of lines that have the same domains that should belong to adjacent domain
                numberInCurrentSetToClaim = NINT((1.0 - portionToDistribute) * numberLinesWithThatSetOfDomains)

                ! if there weren't enough lines assigned to adjacent domain domainToAssignLinesToIdx yet, the domain which will claim this line is found
                IF (numberLinesInDomain(domainToAssignLinesToIdx) < numberInCurrentSetToClaim) THEN
                  EXIT
                ELSE
                  ! if there are no further domainDOFS_MAPPINGs, exit trying to find the next domain
                  IF (domainToAssignLinesToIdx == numberDomains) EXIT

                  ! now that domain has got enough lines, get the next domain
                  domainToAssignLinesToIdx = domainToAssignLinesToIdx + 1
                  CALL LIST_ITEM_GET(domainsOfBoundaryPlaneLineList(boundaryAndBoundaryPlaneLineIdx2)%PTR, &
                    & domainToAssignLinesToIdx, domainToAssignLinesTo,err,error,*999)
                ENDIF
              ENDDO

              ! assign line sharedLineIdx2 to domain domainToAssignLinesTo
              boundaryAndBoundaryPlaneLinesDomain(boundaryAndBoundaryPlaneLineIdx2) = domainToAssignLinesTo

              ! increment count of lines that this domain has claimed in the current set
              numberLinesInDomain(domainToAssignLinesToIdx) = numberLinesInDomain(domainToAssignLinesToIdx) + 1

            ENDIF
          ENDDO  ! sharedLineIdx2
        ENDIF  ! line not yet assigned to domain

      ENDDO  ! sharedLineIdx
    ENDDO  ! adjacentDomainIdx

    ! fill local numbering arrays

    ! create list to hold boundary lines
    NULLIFY(boundaryLinesList)
    CALL LIST_CREATE_START(boundaryLinesList,err,error,*999)
    CALL LIST_DATA_DIMENSION_SET(boundaryLinesList,1,err,error,*999)
    CALL LIST_DATA_TYPE_SET(boundaryLinesList,LIST_INTG_TYPE,err,error,*999)
    CALL LIST_INITIAL_SIZE_SET(boundaryLinesList,CEILING(elementsMapping%NUMBER_OF_LOCAL*0.2),err,error,*999)
    CALL LIST_CREATE_FINISH(boundaryLinesList,err,error,*999)

    ! count number of boundary lines from boundary and boundary plane lines
    DO boundaryAndBoundaryPlaneLineIdx=1,numberBoundaryAndBoundaryPlaneLines
      domainNo = boundaryAndBoundaryPlaneLinesDomain(boundaryAndBoundaryPlaneLineIdx)

      ! if line is a boundary lines and stays on own domain
      IF (domainNo == myComputationalNodeNumber) THEN
        CALL LIST_ITEM_ADD(boundaryLinesList,boundaryAndBoundaryPlaneLineIdx,err,error,*999)
      ENDIF
    ENDDO

    ! extract arrays of local boundary lines
    CALL LIST_DETACH_AND_DESTROY(boundaryLinesList, linesMapping%NUMBER_OF_BOUNDARY, integerArray, err,error,*999)
    ALLOCATE(boundaryLines(linesMapping%NUMBER_OF_BOUNDARY))
    boundaryLines=integerArray(1:linesMapping%NUMBER_OF_BOUNDARY)
    IF(ALLOCATED(integerArray)) DEALLOCATE(integerArray)


    ! create list of ghost lines with their home domain
    NULLIFY(ghostLinesDomainsList)
    CALL LIST_CREATE_START(ghostLinesDomainsList,err,error,*999)
    CALL LIST_DATA_DIMENSION_SET(ghostLinesDomainsList,2,err,error,*999)
    CALL LIST_DATA_TYPE_SET(ghostLinesDomainsList,LIST_INTG_TYPE,err,error,*999)
    CALL LIST_INITIAL_SIZE_SET(ghostLinesDomainsList,MAX(1,numberBoundaryAndBoundaryPlaneLines),err,error,*999)
    CALL LIST_CREATE_FINISH(ghostLinesDomainsList,err,error,*999)

    ! Now exchange the boundary lines that the current domain owns to domains with these lines as ghost lines
    ! allocate send buffers
    ALLOCATE(sendBufferList(elementsMapping%NUMBER_OF_ADJACENT_DOMAINS), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate sendBufferList array with size "//&
      & TRIM(NUMBER_TO_VSTRING(elementsMapping%NUMBER_OF_ADJACENT_DOMAINS,"*",err,error))//".",err,error,*999)

    ALLOCATE(sendRequestHandle0(elementsMapping%NUMBER_OF_ADJACENT_DOMAINS), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate sendRequestHandle0 array with size "//&
      & TRIM(NUMBER_TO_VSTRING(elementsMapping%NUMBER_OF_ADJACENT_DOMAINS,"*",err,error))//".",err,error,*999)

    ALLOCATE(sendRequestHandle1(elementsMapping%NUMBER_OF_ADJACENT_DOMAINS), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate sendRequestHandle1 array with size "//&
      & TRIM(NUMBER_TO_VSTRING(elementsMapping%NUMBER_OF_ADJACENT_DOMAINS,"*",err,error))//".",err,error,*999)

    DO I=1,elementsMapping%NUMBER_OF_ADJACENT_DOMAINS
      NULLIFY(sendBufferList(I)%PTR)
      CALL LIST_CREATE_START(sendBufferList(I)%PTR,err,error,*999)
      CALL LIST_DATA_DIMENSION_SET(sendBufferList(I)%PTR,1,err,error,*999)
      CALL LIST_DATA_TYPE_SET(sendBufferList(I)%PTR,LIST_INTG_TYPE,err,error,*999)
      CALL LIST_INITIAL_SIZE_SET(sendBufferList(I)%PTR,10,err,error,*999)
      CALL LIST_CREATE_FINISH(sendBufferList(I)%PTR,err,error,*999)
    ENDDO

    ! add own boundary and boundary plane lines that are ghost lines on other domains to send buffer for the domains that they will be sent to.

    ! loop over boundary (and boundary plane) lines
    DO boundaryAndBoundaryPlaneLineIdx=1, numberBoundaryAndBoundaryPlaneLines
      lineGlobalNo=boundaryAndBoundaryPlaneLines(boundaryAndBoundaryPlaneLineIdx)

      ! get the domain that owns the line
      domainNo = boundaryAndBoundaryPlaneLinesDomain(boundaryAndBoundaryPlaneLineIdx)

      ! only add to send buffer if it is owned by own domain
      IF (domainNo == myComputationalNodeNumber) THEN

        !Loop over adjacent domains
        DO domainIdx=1,elementsMapping%NUMBER_OF_ADJACENT_DOMAINS

          domainNo2 = elementsMapping%ADJACENT_DOMAINS(DomainIdx)%DOMAIN_NUMBER

          !If domainNo2 has lineGlobalNo as a ghost line we assign it to sendbufferList of domainNo2 which has index domainIdx
          CALL LIST_NUMBER_OF_ITEMS_GET(domainsOfLineList(boundaryAndBoundaryPlaneLineIdx)%PTR,numberDomains, &
            & err,error,*999)
          DO I=1,numberDomains
            CALL LIST_ITEM_GET(domainsOfLineList(boundaryAndBoundaryPlaneLineIdx)%PTR,I, &
              & domainNo3,err,error,*999)

            IF (domainNo2 == domainNo3) THEN
              CALL LIST_ITEM_ADD(sendBufferList(domainIdx)%PTR, lineGlobalNo, err,error,*999)
            ENDIF
          ENDDO !I
        ENDDO !DomainIdx
      ENDIF
    ENDDO

    ! remove duplicates and sort list

    maximumNumberToSend = 0
    DO domainIdx=1,elementsMapping%NUMBER_OF_ADJACENT_DOMAINS
      domainNo = elementsMapping%ADJACENT_DOMAINS(domainIdx)%DOMAIN_NUMBER

      CALL LIST_REMOVE_DUPLICATES(sendBufferList(domainIdx)%PTR,err,error,*999)
      CALL LIST_NUMBER_OF_ITEMS_GET(sendBufferList(domainIdx)%PTR,numberToSend,err,error,*999)
      maximumNumberToSend = MAX(maximumNumberToSend,numberToSend)
    ENDDO

    ALLOCATE(sendBuffer(maximumNumberToSend,elementsMapping%NUMBER_OF_ADJACENT_DOMAINS), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate sendBuffer array with size "//&
      & TRIM(NUMBER_TO_VSTRING(maximumNumberToSend,"*",err,error))//"x"//&
      & TRIM(NUMBER_TO_VSTRING(elementsMapping%NUMBER_OF_ADJACENT_DOMAINS,"*",err,error))//".",err,error,*999)

    ALLOCATE(numberToSendToDomain(elementsMapping%NUMBER_OF_ADJACENT_DOMAINS), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate numberToSendToDomain array with size "//&
      & TRIM(NUMBER_TO_VSTRING(elementsMapping%NUMBER_OF_ADJACENT_DOMAINS,"*",err,error))//".",err,error,*999)

    ! commit send calls
    DO domainIdx=1,elementsMapping%NUMBER_OF_ADJACENT_DOMAINS
      domainNo = elementsMapping%ADJACENT_DOMAINS(domainIdx)%DOMAIN_NUMBER
      CALL LIST_DETACH_AND_DESTROY(sendBufferList(domainIdx)%PTR,numberToSendToDomain(domainIdx),&
        & integerArray,err,error,*999)
      sendBuffer(1:numberToSendToDomain(domainIdx),domainIdx) = integerArray(1:numberToSendToDomain(domainIdx))
      IF(ALLOCATED(integerArray)) DEALLOCATE(integerArray)


      ! number of lines to be send to domain
      CALL MPI_ISEND(numberToSendToDomain(domainIdx),1,MPI_INT,domainNo,0, &
        & computationalEnvironment%mpiCommunicator, sendRequestHandle0(domainIdx), MPI_IERROR)
      CALL MPI_ERROR_CHECK("MPI_ISEND",MPI_IERROR,err,error,*999)

      ! actual global line numbers to send
      IF (numberToSendToDomain(domainIdx) > 0) THEN
        CALL MPI_ISEND(sendBuffer(1:numberToSendToDomain(domainIdx),domainIdx),numberToSendToDomain(domainIdx), &
          & MPI_INT,domainNo,1,computationalEnvironment%mpiCommunicator, sendRequestHandle1(domainIdx), MPI_IERROR)
        CALL MPI_ERROR_CHECK("MPI_ISEND",MPI_IERROR,err,error,*999)
      ENDIF
    ENDDO

    ! receive number of lines to receive
    DO domainIdx=1,elementsMapping%NUMBER_OF_ADJACENT_DOMAINS
      domainNo = elementsMapping%ADJACENT_DOMAINS(domainIdx)%DOMAIN_NUMBER

      CALL MPI_RECV(numberOfLinesToReceive,1,MPI_INT,domainNo,0,computationalEnvironment%mpiCommunicator,MPI_STATUS_IGNORE, &
        & MPI_IERROR)
      CALL MPI_ERROR_CHECK("MPI_RECV",MPI_IERROR,err,error,*999)

      IF (numberOfLinesToReceive>0) THEN
        ALLOCATE(receiveBuffer(numberOfLinesToReceive), STAT=err)
        IF(err/=0) CALL FlagError("Could not allocate receiveBuffer array with size "//&
          & TRIM(NUMBER_TO_VSTRING(numberOfLinesToReceive,"*",err,error))//".",err,error,*999)

        CALL MPI_RECV(receiveBuffer,numberOfLinesToReceive,MPI_INT,domainNo,1, &
          & computationalEnvironment%mpiCommunicator,MPI_STATUS_IGNORE,MPI_IERROR)
        CALL MPI_ERROR_CHECK("MPI_RECV",MPI_IERROR,err,error,*999)

        ! store received ghost lines with domain in ghostLinesDomainsList
        DO I=1,numberOfLinesToReceive
          ghostLineGlobalNo = receiveBuffer(I)
          ghostDomain = domainNo
          CALL LIST_ITEM_ADD(ghostLinesDomainsList,[ghostLineGlobalNo,ghostDomain],err,error,*999)
        ENDDO


        IF(ALLOCATED(receiveBuffer)) DEALLOCATE(receiveBuffer)

      ENDIF
    ENDDO

    ! wait for all communication to finish (Not needed because we use a MPI_RECV not an MPI_IRECV)
    !CALL MPI_WAITALL(elementsMapping%NUMBER_OF_ADJACENT_DOMAINS, sendRequestHandle0, MPI_STATUSES_IGNORE, MPI_IERROR)
    !CALL MPI_ERROR_CHECK("MPI_WAITALL",MPI_IERROR,err,error,*999)

    !CALL MPI_WAITALL(elementsMapping%NUMBER_OF_ADJACENT_DOMAINS, sendRequestHandle1, MPI_STATUSES_IGNORE, MPI_IERROR)
    !CALL MPI_ERROR_CHECK("MPI_WAITALL",MPI_IERROR,err,error,*999)

    !ghostLinesDomains is size (2,number of ghost) where the first entry is the global line number and the second is the domain number of the domain that owns the line
    CALL LIST_SORT(ghostLinesDomainsList,err,error,*999)
    CALL LIST_DETACH_AND_DESTROY(ghostLinesDomainsList,linesMapping%NUMBER_OF_GHOST,integerArray2D,err,error,*999)
    ALLOCATE(ghostLinesDomains(2,linesMapping%NUMBER_OF_GHOST))
    ghostLinesDomains(1,1:linesMapping%NUMBER_OF_GHOST)=integerArray2D(1,1:linesMapping%NUMBER_OF_GHOST)
    ghostLinesDomains(2,1:linesMapping%NUMBER_OF_GHOST)=integerArray2D(2,1:linesMapping%NUMBER_OF_GHOST)

    IF(ALLOCATED(integerArray2D)) DEALLOCATE(integerArray2D)

    !From here on we use numberExtraAdjacentDomains not numberAdjacentDomains because we want the number of domains that communicate ghost/boundary lines

    ! initialize linesMapping%ADJACENT_DOMAINS. Here we want the number of domains that will send/recieve lines with this rank
    linesMapping%NUMBER_OF_ADJACENT_DOMAINS = numberExtraAdjacentDomains

    ! allocate ADJACENT_DOMAINS
    ALLOCATE(linesMapping%ADJACENT_DOMAINS(numberExtraAdjacentDomains), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate adjacent domains array with size "//&
      & TRIM(NUMBER_TO_VSTRING(numberExtraAdjacentDomains,"*",err,error))//".",err,error,*999)

    DO adjacentDomainIdx=1,numberExtraAdjacentDomains
      adjacentDomain = extraAdjacentDomains(adjacentDomainIdx)
      linesMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%DOMAIN_NUMBER = adjacentDomain
      linesMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%NUMBER_OF_SEND_GHOSTS = 0
      linesMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%NUMBER_OF_RECEIVE_GHOSTS = 0
      linesMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%NUMBER_OF_FURTHER_LINKED_GHOSTS = 0
    ENDDO

    ! store number of local and total number of local lines
    linesMapping%NUMBER_OF_LOCAL = linesMapping%NUMBER_OF_INTERNAL + linesMapping%NUMBER_OF_BOUNDARY
    linesMapping%TOTAL_NUMBER_OF_LOCAL = linesMapping%NUMBER_OF_LOCAL + linesMapping%NUMBER_OF_GHOST

    linesMapping%INTERNAL_START=1
    linesMapping%INTERNAL_FINISH=linesMapping%INTERNAL_START+linesMapping%NUMBER_OF_INTERNAL-1
    linesMapping%BOUNDARY_START=linesMapping%INTERNAL_FINISH+1
    linesMapping%BOUNDARY_FINISH=linesMapping%BOUNDARY_START+linesMapping%NUMBER_OF_BOUNDARY-1
    linesMapping%GHOST_START=linesMapping%BOUNDARY_FINISH+1
    linesMapping%GHOST_FINISH=linesMapping%GHOST_START+linesMapping%NUMBER_OF_GHOST-1

    ! allocate LOCAL_TO_GLOBAL_MAP
    ALLOCATE(linesMapping%LOCAL_TO_GLOBAL_MAP(linesMapping%TOTAL_NUMBER_OF_LOCAL), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate lines mapping local to global map with size "//&
      & TRIM(NUMBER_TO_VSTRING(linesMapping%TOTAL_NUMBER_OF_LOCAL,"*",err,error))//".",err,error,*999)

    ! allocate DOMAIN_LIST
    ALLOCATE(linesMapping%DOMAIN_LIST(linesMapping%TOTAL_NUMBER_OF_LOCAL), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate lines mapping domain list with size "//&
      & TRIM(NUMBER_TO_VSTRING(linesMapping%TOTAL_NUMBER_OF_LOCAL,"*",err,error))//".",err,error,*999)

    ! create lists for local ghost send and receive indices
    ALLOCATE(localGhostSendIndices(numberExtraAdjacentDomains), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate localGhostSendIndices with size "//&
      & TRIM(NUMBER_TO_VSTRING(numberExtraAdjacentDomains,"*",err,error))//".",err,error,*999)

    ALLOCATE(localGhostReceiveIndices(numberExtraAdjacentDomains), STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate localGhostReceiveIndices with size "//&
      & TRIM(NUMBER_TO_VSTRING(numberExtraAdjacentDomains,"*",err,error))//".",err,error,*999)

    DO adjacentDomainIdx=1,numberExtraAdjacentDomains

      ! create list for local ghost send indices
      NULLIFY(localGhostSendIndices(adjacentDomainIdx)%PTR)
      CALL LIST_CREATE_START(localGhostSendIndices(adjacentDomainIdx)%PTR,err,error,*999)
      CALL LIST_DATA_DIMENSION_SET(localGhostSendIndices(adjacentDomainIdx)%PTR,1,err,error,*999)
      CALL LIST_DATA_TYPE_SET(localGhostSendIndices(adjacentDomainIdx)%PTR,LIST_INTG_TYPE,err,error,*999)
      CALL LIST_INITIAL_SIZE_SET(localGhostSendIndices(adjacentDomainIdx)%PTR,MAX(1,numberBoundaryAndBoundaryPlaneLines),&
        & err,error,*999)
      CALL LIST_CREATE_FINISH(localGhostSendIndices(adjacentDomainIdx)%PTR,err,error,*999)

      ! create list for local ghost receive indices
      NULLIFY(localGhostReceiveIndices(adjacentDomainIdx)%PTR)
      CALL LIST_CREATE_START(localGhostReceiveIndices(adjacentDomainIdx)%PTR,err,error,*999)
      CALL LIST_DATA_DIMENSION_SET(localGhostReceiveIndices(adjacentDomainIdx)%PTR,1,err,error,*999)
      CALL LIST_DATA_TYPE_SET(localGhostReceiveIndices(adjacentDomainIdx)%PTR,LIST_INTG_TYPE,err,error,*999)
      CALL LIST_INITIAL_SIZE_SET(localGhostReceiveIndices(adjacentDomainIdx)%PTR,MAX(1,numberBoundaryAndBoundaryPlaneLines),&
        & err,error,*999)
      CALL LIST_CREATE_FINISH(localGhostReceiveIndices(adjacentDomainIdx)%PTR,err,error,*999)
    ENDDO

    ! internalLines contains the global numbers of the internal lines

    ! loop over internal and boundary lines and assign local line numbers
    internalLinesIdx = 1
    boundaryLinesIdx = 1
    localLineNo = 1
    domainListInternalIdx = linesMapping%INTERNAL_START
    domainListBoundaryIdx = linesMapping%BOUNDARY_START
    DO WHILE(internalLinesIdx <= linesMapping%NUMBER_OF_INTERNAL &
      & .OR. boundaryLinesIdx <= linesMapping%NUMBER_OF_BOUNDARY)

      ! get next internal or boundary line, ascending with global line number, if there are no more internal or boundary lines, set to -1
      IF (boundaryLinesIdx <= linesMapping%NUMBER_OF_BOUNDARY) THEN
        boundaryAndBoundaryPlaneLineIdx = boundaryLines(boundaryLinesIdx)
        boundaryLineGlobalNo = boundaryAndBoundaryPlaneLines(boundaryAndBoundaryPlaneLineIdx)
      ELSE
        boundaryLineGlobalNo = -1
      ENDIF

      IF (internalLinesIdx <= linesMapping%NUMBER_OF_INTERNAL) THEN
        internalLineGlobalNo = internalLines(internalLinesIdx)
      ELSE
        internalLineGlobalNo = -1
      ENDIF

      IF ((internalLineGlobalNo < boundaryLineGlobalNo .AND. internalLineGlobalNo /= -1) &
        & .OR. boundaryLineGlobalNo == -1) THEN
        ! the next line is an internal line
        linesMapping%DOMAIN_LIST(domainListInternalIdx) = localLineNo
        linesMapping%LOCAL_TO_GLOBAL_MAP(localLineNo) = internalLineGlobalNo
        domainListInternalIdx = domainListInternalIdx + 1
        internalLinesIdx = internalLinesIdx + 1

      ELSE
        ! the next line is a boundary line
        linesMapping%DOMAIN_LIST(domainListBoundaryIdx) = localLineNo
        linesMapping%LOCAL_TO_GLOBAL_MAP(localLineNo) = boundaryLineGlobalNo
        domainListBoundaryIdx = domainListBoundaryIdx + 1
        boundaryLinesIdx = boundaryLinesIdx + 1


        ! update LOCAL_GHOST_SEND_INDICES

        ! loop over the domains where this line is present
        CALL LIST_NUMBER_OF_ITEMS_GET(domainsOfLineList(boundaryAndBoundaryPlaneLineIdx)%PTR, numberDomains, err,error,*999)
        DO I=1,numberDomains
          ! get domain no
          CALL LIST_ITEM_GET(domainsOfLineList(boundaryAndBoundaryPlaneLineIdx)%PTR,I,domainNo,err,error,*999)
          IF (domainNo /= myComputationalNodeNumber) THEN


            found=.FALSE.
            ! go to entry in ADJACENT_DOMAINS array for domainNo, at index adjacentDomainIdx
            DO adjacentDomainIdx =1,numberExtraAdjacentDomains
              IF (extraAdjacentDomains(adjacentDomainIdx) == domainNo) THEN
                found=.TRUE.


                EXIT
              ENDIF
            ENDDO
            IF(.NOT.found) THEN
              localError="Domain number "//TRIM(NumberToVString(domainNo,"*",err,error))// &
              & " was not found in the list of adjacent domains."
              CALL FlagError(localError,err,error,*999)
            ENDIF

            CALL LIST_ITEM_ADD(localGhostSendIndices(adjacentDomainIdx)%PTR,localLineNo,err,error,*999)
          ENDIF
        ENDDO

        domainNo = boundaryAndBoundaryPlaneLinesDomain(boundaryAndBoundaryPlaneLineIdx)

      ENDIF
      localLineNo = localLineNo + 1
    ENDDO

    domainListGhostIdx = linesMapping%GHOST_START
    ! loop over ghost lines
    DO ghostLineIdx = 1,linesMapping%NUMBER_OF_GHOST
      ghostLineGlobalNo = ghostLinesDomains(1,ghostLineIdx)
      ghostDomain = ghostLinesDomains(2,ghostLineIdx)

      linesMapping%DOMAIN_LIST(domainListGhostIdx) = localLineNo
      linesMapping%LOCAL_TO_GLOBAL_MAP(domainListGhostIdx) = ghostLineGlobalNo
      domainListGhostIdx = domainListGhostIdx + 1
      localLineNo = localLineNo + 1

      ! update LOCAL_GHOST_RECEIVE_INDICES


      ! find entry ADJACENT_DOMAINS array for domainNo
      adacentDomainEntryFound = .FALSE.
      DO adjacentDomainIdx=1,linesMapping%NUMBER_OF_ADJACENT_DOMAINS
        IF (linesMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%DOMAIN_NUMBER == ghostDomain) THEN


          CALL LIST_ITEM_ADD(localGhostReceiveIndices(adjacentDomainIdx)%PTR,localLineNo-1,err,error,*999)

          adacentDomainEntryFound = .TRUE.
          EXIT
        ENDIF
      ENDDO ! adjacentDomainIdx

    ENDDO  ! ghostLineIdx

    DO adjacentDomainIdx=1,numberExtraAdjacentDomains
      ! create localGhostSendIndices for the adjacent domain
      CALL LIST_DETACH_AND_DESTROY(localGhostSendIndices(adjacentDomainIdx)%PTR, &
        & linesMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%NUMBER_OF_SEND_GHOSTS,integerArray,err,error,*999)
      linesMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%LOCAL_GHOST_SEND_INDICES = &
        & integerArray(1:linesMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%NUMBER_OF_SEND_GHOSTS)
      IF(ALLOCATED(integerArray)) DEALLOCATE(integerArray)

      ! create localGhostReceiveIndices for the adjacent domain
      CALL LIST_DETACH_AND_DESTROY(localGhostReceiveIndices(adjacentDomainIdx)%PTR, &
        & linesMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%NUMBER_OF_RECEIVE_GHOSTS,integerArray,err,error,*999)
      linesMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%LOCAL_GHOST_RECEIVE_INDICES = &
        & integerArray(1:linesMapping%ADJACENT_DOMAINS(adjacentDomainIdx)%NUMBER_OF_RECEIVE_GHOSTS)
      IF(ALLOCATED(integerArray)) DEALLOCATE(integerArray)

    ENDDO


    ! exchange NUMBER_OF_DOMAIN_LOCAL and NUMBER_OF_DOMAIN_GHOST
    ! allocate number_of_domain_local
    ALLOCATE(linesMapping%NUMBER_OF_DOMAIN_LOCAL(0:numberComputationalNodes-1),STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate NUMBER_OF_DOMAIN_LOCAL.",err,error,*999)

    linesMapping%NUMBER_OF_DOMAIN_LOCAL(myComputationalNodeNumber) = linesMapping%NUMBER_OF_LOCAL

    CALL MPI_ALLGATHER(MPI_IN_PLACE,1,MPI_INTEGER,linesMapping%&
      & NUMBER_OF_DOMAIN_LOCAL(0:numberComputationalNodes-1), &
      & 1,MPI_INTEGER,computationalEnvironment%mpiCommunicator,MPI_IERROR)
    CALL MPI_ERROR_CHECK("MPI_ALLGATHER",MPI_IERROR,err,error,*999)

    ! allocate number_of_domain_ghost
    ALLOCATE(linesMapping%NUMBER_OF_DOMAIN_GHOST(0:numberComputationalNodes-1),STAT=err)
    IF(err/=0) CALL FlagError("Could not allocate NUMBER_OF_DOMAIN_GHOST.",err,error,*999)

    linesMapping%NUMBER_OF_DOMAIN_GHOST(myComputationalNodeNumber) = linesMapping%NUMBER_OF_GHOST

    CALL MPI_ALLGATHER(MPI_IN_PLACE,1,MPI_INTEGER,linesMapping%&
      & NUMBER_OF_DOMAIN_GHOST(0:numberComputationalNodes-1), &
      & 1,MPI_INTEGER,computationalEnvironment%mpiCommunicator,MPI_IERROR)
    CALL MPI_ERROR_CHECK("MPI_ALLGATHER",MPI_IERROR,err,error,*999)


    !The following ADJACENT_DOMAINS_PTR and ADJACENT_DOMAINS_LIST assignment will have to be done in a local way when everything is moved to local not global.

    !allocate and assign domainMappings%ADJACENT_DOMAIN_PTR and domainMappings%ADJACENT_DOMAIN_LIST
    !Currently for elements and nodes this is done in DOMAIN_MAPPINGS_LOCAL_FROM_GLOBAL_CALCULATE
    ALLOCATE(linesMapping%ADJACENT_DOMAINS_PTR(0:linesMapping%NUMBER_OF_DOMAINS),STAT=ERR)
    IF(ERR/=0) CALL FlagError("Could not allocate adjacent domains ptr.",err,error,*999)
    linesMapping%ADJACENT_DOMAINS_PTR=elementsMapping%ADJACENT_DOMAINS_PTR

    ALLOCATE(linesMapping%ADJACENT_DOMAINS_LIST(linesMapping%ADJACENT_DOMAINS_PTR(linesMapping%NUMBER_OF_DOMAINS-1)),STAT=ERR)
    IF(ERR/=0) CALL FlagError("Could not allocate adjacent domains list.",err,error,*999)
    linesMapping%ADJACENT_DOMAINS_LIST=elementsMapping%ADJACENT_DOMAINS_LIST




    !Diagnostics

    IF(DIAGNOSTICS1) THEN
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"Line mappings :",ERR,ERROR,*999)
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Local to global map :",ERR,ERROR,*999)
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Domain No = ",myComputationalNodeNumber,ERR,ERROR,*999)
      DO lineIdx=1,linesMapping%TOTAL_NUMBER_OF_LOCAL
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Local line = ",lineIdx,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Global line = ", &
          & linesMapping%LOCAL_TO_GLOBAL_MAP(lineIdx),ERR,ERROR,*999)
      ENDDO !lineIdx
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Internal lines :",ERR,ERROR,*999)
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Number of internal lines = ", &
        & linesMapping%NUMBER_OF_INTERNAL,ERR,ERROR,*999)
      CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,linesMapping%NUMBER_OF_INTERNAL,8,8, &
        & linesMapping%DOMAIN_LIST(linesMapping%INTERNAL_START:linesMapping%INTERNAL_FINISH), &
        & '("    Internal lines:",8(X,I7))','(19X,8(X,I7))',ERR,ERROR,*999)
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Boundary lines :",ERR,ERROR,*999)
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Number of boundary lines = ", &
        & linesMapping%NUMBER_OF_BOUNDARY,ERR,ERROR,*999)
      CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,linesMapping%NUMBER_OF_BOUNDARY,8,8, &
        & linesMapping%DOMAIN_LIST(linesMapping%BOUNDARY_START:linesMapping%BOUNDARY_FINISH), &
        & '("    Boundary lines:",8(X,I7))','(19X,8(X,I7))',ERR,ERROR,*999)
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Ghost lines :",ERR,ERROR,*999)
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Number of ghost lines = ", &
        & linesMapping%NUMBER_OF_GHOST,ERR,ERROR,*999)
      CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,linesMapping%NUMBER_OF_GHOST,8,8, &
        & linesMapping%DOMAIN_LIST(linesMapping%GHOST_START:linesMapping%GHOST_FINISH), &
        & '("    Ghost lines   :",8(X,I7))','(19X,8(X,I7))',ERR,ERROR,*999)
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Adjacent domains :",ERR,ERROR,*999)
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Number of adjacent domains = ", &
        & linesMapping%NUMBER_OF_ADJACENT_DOMAINS,ERR,ERROR,*999)

      DO domainIdx=1,linesMapping%NUMBER_OF_ADJACENT_DOMAINS
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Adjacent domain idx : ",domainIdx,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Domain number = ", &
          & linesMapping%ADJACENT_DOMAINS(domainIdx)%DOMAIN_NUMBER,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Number of send ghosts    = ", &
          & linesMapping%ADJACENT_DOMAINS(domainIdx)%NUMBER_OF_SEND_GHOSTS,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,linesMapping%ADJACENT_DOMAINS(domainIdx)% &
          & NUMBER_OF_SEND_GHOSTS,6,6,linesMapping%ADJACENT_DOMAINS(domainIdx)%LOCAL_GHOST_SEND_INDICES, &
          & '("      Local send ghost indicies       :",6(X,I7))','(39X,6(X,I7))',ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Number of recieve ghosts = ", &
          & linesMapping%ADJACENT_DOMAINS(domainIdx)%NUMBER_OF_RECEIVE_GHOSTS,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,linesMapping%ADJACENT_DOMAINS(domainIdx)% &
          & NUMBER_OF_RECEIVE_GHOSTS,6,6,linesMapping%ADJACENT_DOMAINS(domainIdx)%LOCAL_GHOST_RECEIVE_INDICES, &
          & '("      Local receive ghost indicies    :",6(X,I7))','(39X,6(X,I7))',ERR,ERROR,*999)
      ENDDO !domainIdx
    ENDIF

    ! deallocate arrays
    IF(ALLOCATED(boundaryAndBoundaryPlaneLines)) DEALLOCATE(boundaryAndBoundaryPlaneLines)
    IF(ALLOCATED(adjacentDomains)) DEALLOCATE(adjacentDomains)
    IF(ALLOCATED(sendRequestHandle)) DEALLOCATE(sendRequestHandle)
    IF(ALLOCATED(receiveRequestHandle)) DEALLOCATE(receiveRequestHandle)
    IF(ALLOCATED(numberNonBoundaryPlaneAndLocalLinesOnRank)) DEALLOCATE(numberNonBoundaryPlaneAndLocalLinesOnRank)
    IF(ALLOCATED(localAndAdjacentDomains)) DEALLOCATE(localAndAdjacentDomains)
    IF(ALLOCATED(boundaryAndBoundaryPlaneLinesDomain)) DEALLOCATE(boundaryAndBoundaryPlaneLinesDomain)
    IF(ALLOCATED(numberLinesInDomain)) DEALLOCATE(numberLinesInDomain)
    IF(ALLOCATED(internalLines)) DEALLOCATE(internalLines)
    IF(ALLOCATED(boundaryLines)) DEALLOCATE(boundaryLines)
    IF(ALLOCATED(sendRequestHandle0)) DEALLOCATE(sendRequestHandle0)
    IF(ALLOCATED(sendRequestHandle1)) DEALLOCATE(sendRequestHandle1)
    IF(ALLOCATED(ghostLinesDomains)) DEALLOCATE(ghostLinesDomains)
    IF(ALLOCATED(sendBuffer)) DEALLOCATE(sendBuffer)
    IF(ALLOCATED(numberToSendToDomain)) DEALLOCATE(numberToSendToDomain)
    IF(ALLOCATED(domainsOfLineList)) DEALLOCATE(domainsOfLineList)
    IF(ALLOCATED(lineOnBoundaryPlane)) DEALLOCATE(lineOnBoundaryPlane)
    IF(ALLOCATED(sharedLinesList)) DEALLOCATE(sharedLinesList)
    IF(ALLOCATED(extraAdjacentDomains)) DEALLOCATE(extraAdjacentDomains)
    IF(ALLOCATED(domainsOfBoundaryPlaneLineList)) DEALLOCATE(domainsOfBoundaryPlaneLineList)

    EXITS("DomainMappings_2DLinesCalculate")
    RETURN
    !FIXTHIS need to make sure I am deallocating the pointers that I assign in the subroutine.
  !998 IF(ALLOCATED(DOMAINS%MAPPINGS)) DEALLOCATE(Domains)
  !FIXTHIS Not sure if i need to deallocate linesMapping%ADJACENT_DOMAINS here
   !IF(ALLOCATED(linesMapping%ADJACENT_DOMAINS)) DEALLOCATE(linesMapping%ADJACENT_DOMAINS)
  999 IF(ASSOCIATED(domain%mesh%topology)) CALL DomainTopology_AssignGlobalLinesFinalise(domain,dummyErr,dummyError,*998)
      IF(ALLOCATED(boundaryAndBoundaryPlaneLines)) DEALLOCATE(boundaryAndBoundaryPlaneLines)
      IF(ALLOCATED(adjacentDomains)) DEALLOCATE(adjacentDomains)
      IF(ALLOCATED(sendRequestHandle)) DEALLOCATE(sendRequestHandle)
      IF(ALLOCATED(receiveRequestHandle)) DEALLOCATE(receiveRequestHandle)
      IF(ALLOCATED(numberNonBoundaryPlaneAndLocalLinesOnRank)) DEALLOCATE(numberNonBoundaryPlaneAndLocalLinesOnRank)
      IF(ALLOCATED(localAndAdjacentDomains)) DEALLOCATE(localAndAdjacentDomains)
      IF(ALLOCATED(boundaryAndBoundaryPlaneLinesDomain)) DEALLOCATE(boundaryAndBoundaryPlaneLinesDomain)
      IF(ALLOCATED(numberLinesInDomain)) DEALLOCATE(numberLinesInDomain)
      IF(ALLOCATED(internalLines)) DEALLOCATE(internalLines)
      IF(ALLOCATED(boundaryLines)) DEALLOCATE(boundaryLines)
      IF(ALLOCATED(sendRequestHandle0)) DEALLOCATE(sendRequestHandle0)
      IF(ALLOCATED(sendRequestHandle1)) DEALLOCATE(sendRequestHandle1)
      IF(ALLOCATED(ghostLinesDomains)) DEALLOCATE(ghostLinesDomains)
      IF(ALLOCATED(sendBuffer)) DEALLOCATE(sendBuffer)
      IF(ALLOCATED(numberToSendToDomain)) DEALLOCATE(numberToSendToDomain)
      IF(ALLOCATED(domainsOfLineList)) DEALLOCATE(domainsOfLineList)
      IF(ALLOCATED(lineOnBoundaryPlane)) DEALLOCATE(lineOnBoundaryPlane)
      IF(ALLOCATED(sharedLinesList)) DEALLOCATE(sharedLinesList)
      IF(ALLOCATED(extraAdjacentDomains)) DEALLOCATE(extraAdjacentDomains)
      IF(ALLOCATED(domainsOfBoundaryPlaneLineList)) DEALLOCATE(domainsOfBoundaryPlaneLineList)
  998 ERRORSEXITS("DomainMappings_2DLinesCalculate",err,error)
    RETURN 1
  END SUBROUTINE DomainMappings_2DLinesCalculate
  !
  !================================================================================================================================
  !

  !>Calculates the local/global node and dof mappings for a domain decomposition.
  SUBROUTINE DOMAIN_MAPPINGS_NODES_DOFS_CALCULATE(DOMAIN,err,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_TYPE), POINTER :: DOMAIN !<A pointer to the domain to calculate the node dofs for.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR,no_adjacent_element,no_computational_node,no_ghost_node,adjacent_element,ghost_node, &
      & NUMBER_OF_NODES_PER_DOMAIN,domain_idx,domain_idx2,domain_no,node_idx,derivative_idx,version_idx,ny,NUMBER_OF_DOMAINS, &
      & MAX_NUMBER_DOMAINS,NUMBER_OF_GHOST_NODES,myComputationalNodeNumber,numberOfComputationalNodes,component_idx
    INTEGER(INTG), ALLOCATABLE :: LOCAL_NODE_NUMBERS(:),LOCAL_DOF_NUMBERS(:),NODE_COUNT(:),NUMBER_INTERNAL_NODES(:), &
      & NUMBER_BOUNDARY_NODES(:), boundaryPlane(:)
    INTEGER(INTG), ALLOCATABLE :: DOMAINS(:),ALL_DOMAINS(:),GHOST_NODES(:)
    LOGICAL :: BOUNDARY_DOMAIN
    TYPE(LIST_TYPE), POINTER :: ADJACENT_DOMAINS_LIST,ALL_ADJACENT_DOMAINS_LIST
    TYPE(LIST_PTR_TYPE), ALLOCATABLE :: GHOST_NODES_LIST(:)
    TYPE(MESH_TYPE), POINTER :: MESH
    TYPE(MeshComponentTopologyType), POINTER :: MESH_TOPOLOGY
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: ELEMENTS_MAPPING
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: NODES_MAPPING
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: DOFS_MAPPING
    TYPE(VARYING_STRING) :: DUMMY_ERROR,LOCAL_ERROR

    ENTERS("DOMAIN_MAPPINGS_NODES_DOFS_CALCULATE",ERR,ERROR,*999)

    IF(ASSOCIATED(DOMAIN)) THEN
      IF(ASSOCIATED(DOMAIN%MAPPINGS)) THEN
        IF(ASSOCIATED(DOMAIN%MAPPINGS%NODES)) THEN
          NODES_MAPPING=>DOMAIN%MAPPINGS%NODES
          IF(ASSOCIATED(DOMAIN%MAPPINGS%DOFS)) THEN
            DOFS_MAPPING=>DOMAIN%MAPPINGS%DOFS
            IF(ASSOCIATED(DOMAIN%MAPPINGS%ELEMENTS)) THEN
              ELEMENTS_MAPPING=>DOMAIN%MAPPINGS%ELEMENTS
              IF(ASSOCIATED(DOMAIN%DECOMPOSITION)) THEN
                DECOMPOSITION=>DOMAIN%DECOMPOSITION
                IF(ASSOCIATED(DOMAIN%MESH)) THEN
                  MESH=>DOMAIN%MESH
                  component_idx=DOMAIN%MESH_COMPONENT_NUMBER
                  MESH_TOPOLOGY=>MESH%TOPOLOGY(component_idx)%PTR

                  numberOfComputationalNodes=ComputationalEnvironment_NumberOfNodesGet(ERR,ERROR)
                  IF(ERR/=0) GOTO 999
                  myComputationalNodeNumber=ComputationalEnvironment_NodeNumberGet(ERR,ERROR)
                  IF(ERR/=0) GOTO 999

                  !Calculate the local and global numbers and set up the mappings
                  ALLOCATE(NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(MESH_TOPOLOGY%NODES%numberOfNodes),STAT=ERR)
                  IF(ERR/=0) CALL FlagError("Could not allocate node mapping global to local map.",ERR,ERROR,*999)
                  NODES_MAPPING%NUMBER_OF_GLOBAL=MESH_TOPOLOGY%NODES%numberOfNodes
                  ALLOCATE(LOCAL_NODE_NUMBERS(0:DECOMPOSITION%NUMBER_OF_DOMAINS-1),STAT=ERR)
                  IF(ERR/=0) CALL FlagError("Could not allocate local node numbers.",ERR,ERROR,*999)
                  LOCAL_NODE_NUMBERS=0
                  ALLOCATE(DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(MESH_TOPOLOGY%dofs%numberOfDofs),STAT=ERR)
                  IF(ERR/=0) CALL FlagError("Could not allocate dofs mapping global to local map.",ERR,ERROR,*999)
                  DOFS_MAPPING%NUMBER_OF_GLOBAL=MESH_TOPOLOGY%DOFS%numberOfDofs
                  ALLOCATE(LOCAL_DOF_NUMBERS(0:DECOMPOSITION%NUMBER_OF_DOMAINS-1),STAT=ERR)
                  IF(ERR/=0) CALL FlagError("Could not allocate local dof numbers.",ERR,ERROR,*999)
                  LOCAL_DOF_NUMBERS=0
                  ALLOCATE(GHOST_NODES_LIST(0:DECOMPOSITION%NUMBER_OF_DOMAINS-1),STAT=ERR)
                  IF(ERR/=0) CALL FlagError("Could not allocate ghost nodes list.",ERR,ERROR,*999)
                  DO domain_idx=0,DECOMPOSITION%NUMBER_OF_DOMAINS-1
                    NULLIFY(GHOST_NODES_LIST(domain_idx)%PTR)
                    CALL LIST_CREATE_START(GHOST_NODES_LIST(domain_idx)%PTR,ERR,ERROR,*999)
                    CALL LIST_DATA_TYPE_SET(GHOST_NODES_LIST(domain_idx)%PTR,LIST_INTG_TYPE,ERR,ERROR,*999)
                    CALL LIST_INITIAL_SIZE_SET(GHOST_NODES_LIST(domain_idx)%PTR,INT(MESH_TOPOLOGY%NODES%numberOfNodes/2), &
                      & ERR,ERROR,*999)
                    CALL LIST_CREATE_FINISH(GHOST_NODES_LIST(domain_idx)%PTR,ERR,ERROR,*999)
                  ENDDO !domain_idx
                  ALLOCATE(NUMBER_INTERNAL_NODES(0:DECOMPOSITION%NUMBER_OF_DOMAINS-1),STAT=ERR)
                  IF(ERR/=0) CALL FlagError("Could not allocate number of internal nodes.",ERR,ERROR,*999)
                  NUMBER_INTERNAL_NODES=0
                  ALLOCATE(NUMBER_BOUNDARY_NODES(0:DECOMPOSITION%NUMBER_OF_DOMAINS-1),STAT=ERR)
                  IF(ERR/=0) CALL FlagError("Could not allocate number of boundary nodes.",ERR,ERROR,*999)
                  NUMBER_BOUNDARY_NODES=0

                  !Temporary Fix
                  ALLOCATE(boundaryPlane(MESH_TOPOLOGY%NODES%numberOfNodes))
                  boundaryPlane = -1
                  !For the first pass just determine the internal and boundary nodes
                  DO node_idx=1,MESH_TOPOLOGY%NODES%numberOfNodes
                    NULLIFY(ADJACENT_DOMAINS_LIST)
                    CALL LIST_CREATE_START(ADJACENT_DOMAINS_LIST,ERR,ERROR,*999)
                    CALL LIST_DATA_TYPE_SET(ADJACENT_DOMAINS_LIST,LIST_INTG_TYPE,ERR,ERROR,*999)
                    CALL LIST_INITIAL_SIZE_SET(ADJACENT_DOMAINS_LIST,DECOMPOSITION%NUMBER_OF_DOMAINS,ERR,ERROR,*999)
                    CALL LIST_CREATE_FINISH(ADJACENT_DOMAINS_LIST,ERR,ERROR,*999)
                    NULLIFY(ALL_ADJACENT_DOMAINS_LIST)
                    CALL LIST_CREATE_START(ALL_ADJACENT_DOMAINS_LIST,ERR,ERROR,*999)
                    CALL LIST_DATA_TYPE_SET(ALL_ADJACENT_DOMAINS_LIST,LIST_INTG_TYPE,ERR,ERROR,*999)
                    CALL LIST_INITIAL_SIZE_SET(ALL_ADJACENT_DOMAINS_LIST,DECOMPOSITION%NUMBER_OF_DOMAINS,ERR,ERROR,*999)
                    CALL LIST_CREATE_FINISH(ALL_ADJACENT_DOMAINS_LIST,ERR,ERROR,*999)
                    DO no_adjacent_element=1,MESH_TOPOLOGY%NODES%NODES(node_idx)%numberOfSurroundingElements
                      adjacent_element=MESH_TOPOLOGY%NODES%NODES(node_idx)%surroundingElements(no_adjacent_element)
                      domain_no=DECOMPOSITION%ELEMENT_DOMAIN(adjacent_element)
                      CALL LIST_ITEM_ADD(ADJACENT_DOMAINS_LIST,domain_no,ERR,ERROR,*999)
                      DO domain_idx=1,ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(adjacent_element)%NUMBER_OF_DOMAINS
                        CALL LIST_ITEM_ADD(ALL_ADJACENT_DOMAINS_LIST,ELEMENTS_MAPPING%GLOBAL_TO_LOCAL_MAP(adjacent_element)% &
                          & DOMAIN_NUMBER(domain_idx),ERR,ERROR,*999)
                      ENDDO !domain_idx
                    ENDDO !no_adjacent_element
                    CALL LIST_REMOVE_DUPLICATES(ADJACENT_DOMAINS_LIST,ERR,ERROR,*999)
                    CALL LIST_DETACH_AND_DESTROY(ADJACENT_DOMAINS_LIST,NUMBER_OF_DOMAINS,DOMAINS,ERR,ERROR,*999)
                    CALL LIST_REMOVE_DUPLICATES(ALL_ADJACENT_DOMAINS_LIST,ERR,ERROR,*999)
                    CALL LIST_DETACH_AND_DESTROY(ALL_ADJACENT_DOMAINS_LIST,MAX_NUMBER_DOMAINS,ALL_DOMAINS,ERR,ERROR,*999)
                    IF(NUMBER_OF_DOMAINS/=MAX_NUMBER_DOMAINS) THEN !Ghost node
                      DO domain_idx=1,MAX_NUMBER_DOMAINS
                        domain_no=ALL_DOMAINS(domain_idx)
                        BOUNDARY_DOMAIN=.FALSE.
                        DO domain_idx2=1,NUMBER_OF_DOMAINS
                          IF(domain_no==DOMAINS(domain_idx2)) THEN
                            BOUNDARY_DOMAIN=.TRUE.
                            EXIT
                          ENDIF
                        ENDDO !domain_idx2
                        IF(.NOT.BOUNDARY_DOMAIN) CALL LIST_ITEM_ADD(GHOST_NODES_LIST(domain_no)%PTR,node_idx,ERR,ERROR,*999)
                      ENDDO !domain_idx
                    ENDIF
                    ALLOCATE(NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%LOCAL_NUMBER(MAX_NUMBER_DOMAINS),STAT=ERR)
                    IF(ERR/=0) CALL FlagError("Could not allocate node global to local map local number.",ERR,ERROR,*999)
                    ALLOCATE(NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%DOMAIN_NUMBER(MAX_NUMBER_DOMAINS),STAT=ERR)
                    IF(ERR/=0) CALL FlagError("Could not allocate node global to local map domain number.",ERR,ERROR,*999)
                    ALLOCATE(NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%LOCAL_TYPE(MAX_NUMBER_DOMAINS),STAT=ERR)
                    IF(ERR/=0) CALL FlagError("Could not allocate node global to local map local type.",ERR,ERROR,*999)
                    DO derivative_idx=1,MESH_TOPOLOGY%NODES%NODES(node_idx)%numberOfDerivatives
                      DO version_idx=1,MESH_TOPOLOGY%NODES%NODES(node_idx)%DERIVATIVES(derivative_idx)%numberOfVersions
                        ny=MESH_TOPOLOGY%NODES%NODES(node_idx)%DERIVATIVES(derivative_idx)%dofIndex(version_idx)
                        ALLOCATE(DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%LOCAL_NUMBER(MAX_NUMBER_DOMAINS),STAT=ERR)
                        IF(ERR/=0) CALL FlagError("Could not allocate dof global to local map local number.",ERR,ERROR,*999)
                        ALLOCATE(DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%DOMAIN_NUMBER(MAX_NUMBER_DOMAINS),STAT=ERR)
                        IF(ERR/=0) CALL FlagError("Could not allocate dof global to local map domain number.",ERR,ERROR,*999)
                        ALLOCATE(DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%LOCAL_TYPE(MAX_NUMBER_DOMAINS),STAT=ERR)
                        IF(ERR/=0) CALL FlagError("Could not allocate dof global to local map local type.",ERR,ERROR,*999)
                      ENDDO !version_idx
                    ENDDO !derivative_idx
                    IF(MAX_NUMBER_DOMAINS==1) THEN

                      !Node is an internal node
                      domain_no=DOMAINS(1)
                      NUMBER_INTERNAL_NODES(domain_no)=NUMBER_INTERNAL_NODES(domain_no)+1
                      !LOCAL_NODE_NUMBERS(domain_no)=LOCAL_NODE_NUMBERS(domain_no)+1
                      NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%NUMBER_OF_DOMAINS=MAX_NUMBER_DOMAINS
                      !NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%LOCAL_NUMBER(1)=LOCAL_NODE_NUMBERS(DOMAINS(1))
                      NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%LOCAL_NUMBER(1)=-1
                      NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%DOMAIN_NUMBER(1)=DOMAINS(1)
                      NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%LOCAL_TYPE(1)=DOMAIN_LOCAL_INTERNAL
                      DO derivative_idx=1,MESH_TOPOLOGY%NODES%NODES(node_idx)%numberOfDerivatives
                        DO version_idx=1,MESH_TOPOLOGY%NODES%NODES(node_idx)%DERIVATIVES(derivative_idx)%numberOfVersions
                          ny=MESH_TOPOLOGY%NODES%NODES(node_idx)%DERIVATIVES(derivative_idx)%dofIndex(version_idx)
                          DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%NUMBER_OF_DOMAINS=MAX_NUMBER_DOMAINS
                          DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%LOCAL_NUMBER(1)=-1
                          DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%DOMAIN_NUMBER(1)=domain_no
                          DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%LOCAL_TYPE(1)=DOMAIN_LOCAL_INTERNAL
                        ENDDO !version_idx
                      ENDDO !derivative_idx
                    ELSE
                      IF(NUMBER_OF_DOMAINS==1) THEN
                        ! node is a boundary but not on the border between domains
                        boundaryPlane(node_idx) = 0
                      ELSE
                        boundaryPlane(node_idx) = 1
                      ENDIF
                      !Node is on the boundary plane of computational domains
                      NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%NUMBER_OF_DOMAINS=MAX_NUMBER_DOMAINS
                      DO derivative_idx=1,MESH_TOPOLOGY%NODES%NODES(node_idx)%numberOfDerivatives
                        DO version_idx=1,MESH_TOPOLOGY%NODES%NODES(node_idx)%DERIVATIVES(derivative_idx)%numberOfVersions
                          ny=MESH_TOPOLOGY%NODES%NODES(node_idx)%DERIVATIVES(derivative_idx)%dofIndex(version_idx)
                          DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%NUMBER_OF_DOMAINS=MAX_NUMBER_DOMAINS
                        ENDDO !version_idx
                      ENDDO !derivative_idx
                      DO domain_idx=1,MAX_NUMBER_DOMAINS
                        domain_no=ALL_DOMAINS(domain_idx)
                        !LOCAL_NODE_NUMBERS(domain_no)=LOCAL_NODE_NUMBERS(domain_no)+1
                        !NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%LOCAL_NUMBER(domain_idx)=LOCAL_NODE_NUMBERS(domain_no)
                        NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%LOCAL_NUMBER(domain_idx)=-1
                        NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%DOMAIN_NUMBER(domain_idx)=domain_no
                        NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%LOCAL_TYPE(domain_idx)=DOMAIN_LOCAL_BOUNDARY
                        DO derivative_idx=1,MESH_TOPOLOGY%NODES%NODES(node_idx)%numberOfDerivatives
                          DO version_idx=1,MESH_TOPOLOGY%NODES%NODES(node_idx)%DERIVATIVES(derivative_idx)%numberOfVersions
                            ny=MESH_TOPOLOGY%NODES%NODES(node_idx)%DERIVATIVES(derivative_idx)%dofIndex(version_idx)
                            DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%LOCAL_NUMBER(domain_idx)=-1
                            DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%DOMAIN_NUMBER(domain_idx)=domain_no
                            DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%LOCAL_TYPE(domain_idx)=DOMAIN_LOCAL_BOUNDARY
                          ENDDO !version_idx
                        ENDDO !derivative_idx
                      ENDDO !domain_idx
                    ENDIF
                    DEALLOCATE(DOMAINS)
                    DEALLOCATE(ALL_DOMAINS)
                  ENDDO !node_idx

                  !For the second pass assign boundary nodes to one domain on the boundary and set local node numbers.
                  NUMBER_OF_NODES_PER_DOMAIN=FLOOR(REAL(MESH_TOPOLOGY%NODES%numberOfNodes,DP)/ &
                    & REAL(DECOMPOSITION%NUMBER_OF_DOMAINS,DP))
                  ALLOCATE(DOMAIN%NODE_DOMAIN(MESH_TOPOLOGY%NODES%numberOfNodes),STAT=ERR)
                  IF(ERR/=0) CALL FlagError("Could not allocate node domain",ERR,ERROR,*999)
                  DOMAIN%NODE_DOMAIN=-1
                  DO node_idx=1,MESH_TOPOLOGY%NODES%numberOfNodes
                    IF(NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%NUMBER_OF_DOMAINS==1) THEN !Internal node
                      domain_no=NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%DOMAIN_NUMBER(1)
                      DOMAIN%NODE_DOMAIN(node_idx)=domain_no
                      LOCAL_NODE_NUMBERS(domain_no)=LOCAL_NODE_NUMBERS(domain_no)+1
                      NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%LOCAL_NUMBER(1)=LOCAL_NODE_NUMBERS(domain_no)
                      DO derivative_idx=1,MESH_TOPOLOGY%NODES%NODES(node_idx)%numberOfDerivatives
                        DO version_idx=1,MESH_TOPOLOGY%NODES%NODES(node_idx)%DERIVATIVES(derivative_idx)%numberOfVersions
                          ny=MESH_TOPOLOGY%NODES%NODES(node_idx)%DERIVATIVES(derivative_idx)%dofIndex(version_idx)
                          LOCAL_DOF_NUMBERS(domain_no)=LOCAL_DOF_NUMBERS(domain_no)+1
                          DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%LOCAL_NUMBER(1)=LOCAL_DOF_NUMBERS(domain_no)
                        ENDDO !version_idx
                      ENDDO !derivative_idx
                    ELSEIF(boundaryPlane(node_idx)/=1) THEN
                      !boundary nodes that aren't on the boundary plane get assigned as boundary nodes.
                      !Allocate the node to this domain

                      !the domain number is that of any adjacent element
                      adjacent_element=MESH_TOPOLOGY%NODES%NODES(node_idx)%surroundingElements(1)
                      domain_no=DECOMPOSITION%ELEMENT_DOMAIN(adjacent_element)
                      DOMAIN%NODE_DOMAIN(node_idx)=domain_no
                      NUMBER_BOUNDARY_NODES(domain_no)=NUMBER_BOUNDARY_NODES(domain_no)+1
                      LOCAL_NODE_NUMBERS(domain_no)=LOCAL_NODE_NUMBERS(domain_no)+1
                      !Reset the boundary information to be in the first domain index. The remaining domain indicies will
                      !be overwritten when the ghost nodes are calculated below.
                      NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%LOCAL_NUMBER(1)=LOCAL_NODE_NUMBERS(domain_no)
                      NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%DOMAIN_NUMBER(1)=domain_no
                      NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%LOCAL_TYPE(1)=DOMAIN_LOCAL_BOUNDARY
                      DO derivative_idx=1,MESH_TOPOLOGY%NODES%NODES(node_idx)%numberOfDerivatives
                        DO version_idx=1,MESH_TOPOLOGY%NODES%NODES(node_idx)%DERIVATIVES(derivative_idx)%numberOfVersions
                          ny=MESH_TOPOLOGY%NODES%NODES(node_idx)%DERIVATIVES(derivative_idx)%dofIndex(version_idx)
                          LOCAL_DOF_NUMBERS(domain_no)=LOCAL_DOF_NUMBERS(domain_no)+1
                          DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%LOCAL_NUMBER(1)=LOCAL_DOF_NUMBERS(domain_no)
                          DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%DOMAIN_NUMBER(1)=domain_no
                          DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%LOCAL_TYPE(1)=DOMAIN_LOCAL_BOUNDARY
                        ENDDO !version_idx
                      ENDDO !derivative_idx

                    ELSE !Boundary node
                      NUMBER_OF_DOMAINS=NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%NUMBER_OF_DOMAINS
                      DO domain_idx=1,NUMBER_OF_DOMAINS
                        domain_no=NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%DOMAIN_NUMBER(domain_idx)
                        IF(DOMAIN%NODE_DOMAIN(node_idx)<0) THEN
                          IF((NUMBER_INTERNAL_NODES(domain_no)+NUMBER_BOUNDARY_NODES(domain_no)<NUMBER_OF_NODES_PER_DOMAIN).OR. &
                            & (domain_idx==NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%NUMBER_OF_DOMAINS)) THEN
                            !Allocate the node to this domain
                            DOMAIN%NODE_DOMAIN(node_idx)=domain_no
                            NUMBER_BOUNDARY_NODES(domain_no)=NUMBER_BOUNDARY_NODES(domain_no)+1
                            LOCAL_NODE_NUMBERS(domain_no)=LOCAL_NODE_NUMBERS(domain_no)+1
                            !Reset the boundary information to be in the first domain index. The remaining domain indicies will
                            !be overwritten when the ghost nodes are calculated below.
                            NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%LOCAL_NUMBER(1)=LOCAL_NODE_NUMBERS(domain_no)
                            NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%DOMAIN_NUMBER(1)=domain_no
                            NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%LOCAL_TYPE(1)=DOMAIN_LOCAL_BOUNDARY
                            DO derivative_idx=1,MESH_TOPOLOGY%NODES%NODES(node_idx)%numberOfDerivatives
                              DO version_idx=1,MESH_TOPOLOGY%NODES%NODES(node_idx)%DERIVATIVES(derivative_idx)%numberOfVersions
                                ny=MESH_TOPOLOGY%NODES%NODES(node_idx)%DERIVATIVES(derivative_idx)%dofIndex(version_idx)
                                LOCAL_DOF_NUMBERS(domain_no)=LOCAL_DOF_NUMBERS(domain_no)+1
                                DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%LOCAL_NUMBER(1)=LOCAL_DOF_NUMBERS(domain_no)
                                DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%DOMAIN_NUMBER(1)=domain_no
                                DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%LOCAL_TYPE(1)=DOMAIN_LOCAL_BOUNDARY
                              ENDDO !version_idx
                            ENDDO !derivative_idx
                          ELSE
                            !The node as already been assigned to a domain so it must be a ghost node in this domain
                            CALL LIST_ITEM_ADD(GHOST_NODES_LIST(domain_no)%PTR,node_idx,ERR,ERROR,*999)
                          ENDIF
                        ELSE
                          !The node as already been assigned to a domain so it must be a ghost node in this domain
                          CALL LIST_ITEM_ADD(GHOST_NODES_LIST(domain_no)%PTR,node_idx,ERR,ERROR,*999)
                        ENDIF
                      ENDDO !domain_idx
                    ENDIF

                    !Reset the number of domains for each node, this will be increased for each ghost.
                    NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%NUMBER_OF_DOMAINS=1
                    DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%NUMBER_OF_DOMAINS=1


                  ENDDO !node_idx
                  DEALLOCATE(NUMBER_INTERNAL_NODES)

                  !Calculate ghost node and dof mappings
                  DO domain_idx=0,DECOMPOSITION%NUMBER_OF_DOMAINS-1
                    CALL LIST_REMOVE_DUPLICATES(GHOST_NODES_LIST(domain_idx)%PTR,ERR,ERROR,*999)
                    CALL LIST_DETACH_AND_DESTROY(GHOST_NODES_LIST(domain_idx)%PTR,NUMBER_OF_GHOST_NODES,GHOST_NODES,ERR,ERROR,*999)
                    DO no_ghost_node=1,NUMBER_OF_GHOST_NODES
                      ghost_node=GHOST_NODES(no_ghost_node)
                      LOCAL_NODE_NUMBERS(domain_idx)=LOCAL_NODE_NUMBERS(domain_idx)+1
                      NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(ghost_node)%NUMBER_OF_DOMAINS= &
                        & NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(ghost_node)%NUMBER_OF_DOMAINS+1
                      NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(ghost_node)%LOCAL_NUMBER( &
                        & NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(ghost_node)%NUMBER_OF_DOMAINS)= &
                        & LOCAL_NODE_NUMBERS(domain_idx)
                      NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(ghost_node)%DOMAIN_NUMBER( &
                        & NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(ghost_node)%NUMBER_OF_DOMAINS)=domain_idx
                      NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(ghost_node)%LOCAL_TYPE( &
                        & NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(ghost_node)%NUMBER_OF_DOMAINS)= &
                        & DOMAIN_LOCAL_GHOST
                      DO derivative_idx=1,MESH_TOPOLOGY%NODES%NODES(ghost_node)%numberOfDerivatives
                        DO version_idx=1,MESH_TOPOLOGY%NODES%NODES(ghost_node)%DERIVATIVES(derivative_idx)%numberOfVersions
                          ny=MESH_TOPOLOGY%NODES%NODES(ghost_node)%DERIVATIVES(derivative_idx)%dofIndex(version_idx)
                          LOCAL_DOF_NUMBERS(domain_idx)=LOCAL_DOF_NUMBERS(domain_idx)+1
                          DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%NUMBER_OF_DOMAINS= &
                            & DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%NUMBER_OF_DOMAINS+1
                          DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%LOCAL_NUMBER( &
                            & DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%NUMBER_OF_DOMAINS)= &
                            & LOCAL_DOF_NUMBERS(domain_idx)
                          DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%DOMAIN_NUMBER( &
                            & DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%NUMBER_OF_DOMAINS)=domain_idx
                          DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%LOCAL_TYPE( &
                            & DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%NUMBER_OF_DOMAINS)= &
                            & DOMAIN_LOCAL_GHOST
                        ENDDO !version_idx
                      ENDDO !derivative_idx
                    ENDDO !no_ghost_node
                    DEALLOCATE(GHOST_NODES)
                  ENDDO !domain_idx

                  !Check decomposition and check that each domain has a node in it.
                  ALLOCATE(NODE_COUNT(0:numberOfComputationalNodes-1),STAT=ERR)
                  IF(ERR/=0) CALL FlagError("Could not allocate node count.",ERR,ERROR,*999)
                  NODE_COUNT=0
                  DO node_idx=1,MESH_TOPOLOGY%NODES%numberOfNodes
                    no_computational_node=DOMAIN%NODE_DOMAIN(node_idx)
                    IF(no_computational_node>=0.AND.no_computational_node<numberOfComputationalNodes) THEN
                      NODE_COUNT(no_computational_node)=NODE_COUNT(no_computational_node)+1
                    ELSE
                      LOCAL_ERROR="The computational node number of "// &
                        & TRIM(NUMBER_TO_VSTRING(no_computational_node,"*",ERR,ERROR))// &
                        & " for node number "//TRIM(NUMBER_TO_VSTRING(node_idx,"*",ERR,ERROR))// &
                        & " is invalid. The computational node number must be between 0 and "// &
                        & TRIM(NUMBER_TO_VSTRING(numberOfComputationalNodes-1,"*",ERR,ERROR))//"."
                      CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                    ENDIF
                  ENDDO !node_idx
                  DO no_computational_node=0,numberOfComputationalNodes-1
                    IF(NODE_COUNT(no_computational_node)==0) THEN
                      LOCAL_ERROR="Invalid decomposition. There are no nodes in computational node "// &
                        & TRIM(NUMBER_TO_VSTRING(no_computational_node,"*",ERR,ERROR))//"."
                      CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                    ENDIF
                  ENDDO !no_computational_node
                  DEALLOCATE(NODE_COUNT)

                  DEALLOCATE(GHOST_NODES_LIST)
                  DEALLOCATE(LOCAL_NODE_NUMBERS)

                  !Calculate node and dof local to global maps from global to local map
                  CALL DOMAIN_MAPPINGS_LOCAL_FROM_GLOBAL_CALCULATE(NODES_MAPPING,ERR,ERROR,*999)
                  CALL DOMAIN_MAPPINGS_LOCAL_FROM_GLOBAL_CALCULATE(DOFS_MAPPING,ERR,ERROR,*999)

                ELSE
                  CALL FlagError("Domain mesh is not associated.",ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FlagError("Domain decomposition is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FlagError("Domain mappings elements is not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Domain mappings dofs is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Domain mappings nodes is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Domain mappings is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Domain is not associated.",ERR,ERROR,*998)
    ENDIF

    IF(DIAGNOSTICS1) THEN
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"Node decomposition :",ERR,ERROR,*999)
      DO node_idx=1,MESH_TOPOLOGY%NODES%numberOfNodes
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  Node = ",node_idx,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Domain = ",DOMAIN%NODE_DOMAIN(node_idx),ERR,ERROR,*999)
      ENDDO !node_idx
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"Node mappings :",ERR,ERROR,*999)
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Global to local map :",ERR,ERROR,*999)
      DO node_idx=1,MESH_TOPOLOGY%NODES%numberOfNodes
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Global node = ",node_idx,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Number of domains  = ", &
          & NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%NUMBER_OF_DOMAINS,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)% &
          & NUMBER_OF_DOMAINS,8,8,NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%LOCAL_NUMBER, &
          & '("      Local number :",8(X,I7))','(20X,8(X,I7))',ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)% &
            & NUMBER_OF_DOMAINS,8,8,NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%DOMAIN_NUMBER, &
            & '("      Domain number:",8(X,I7))','(20X,8(X,I7))',ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)% &
          & NUMBER_OF_DOMAINS,8,8,NODES_MAPPING%GLOBAL_TO_LOCAL_MAP(node_idx)%LOCAL_TYPE, &
          & '("      Local type   :",8(X,I7))','(20X,8(X,I7))',ERR,ERROR,*999)
      ENDDO !node_idx
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Local to global map :",ERR,ERROR,*999)
      DO node_idx=1,NODES_MAPPING%TOTAL_NUMBER_OF_LOCAL
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Local node = ",node_idx,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Global node = ", &
          & NODES_MAPPING%LOCAL_TO_GLOBAL_MAP(node_idx),ERR,ERROR,*999)
      ENDDO !node_idx
      IF(DIAGNOSTICS2) THEN
        CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Internal nodes :",ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Number of internal nodes = ", &
          & NODES_MAPPING%NUMBER_OF_INTERNAL,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,NODES_MAPPING%NUMBER_OF_INTERNAL,8,8, &
          & NODES_MAPPING%DOMAIN_LIST(NODES_MAPPING%INTERNAL_START:NODES_MAPPING%INTERNAL_FINISH), &
          & '("    Internal nodes:",8(X,I7))','(19X,8(X,I7))',ERR,ERROR,*999)
        CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Boundary nodes :",ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Number of boundary nodes = ", &
          & NODES_MAPPING%NUMBER_OF_BOUNDARY,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,NODES_MAPPING%NUMBER_OF_BOUNDARY,8,8, &
          & NODES_MAPPING%DOMAIN_LIST(NODES_MAPPING%BOUNDARY_START:NODES_MAPPING%BOUNDARY_FINISH), &
          & '("    Boundary nodes:",8(X,I7))','(19X,8(X,I7))',ERR,ERROR,*999)
        CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Ghost nodes :",ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Number of ghost nodes = ", &
          & NODES_MAPPING%NUMBER_OF_GHOST,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,NODES_MAPPING%NUMBER_OF_GHOST,8,8, &
          & NODES_MAPPING%DOMAIN_LIST(NODES_MAPPING%GHOST_START:NODES_MAPPING%GHOST_FINISH), &
          & '("    Ghost nodes   :",8(X,I7))','(19X,8(X,I7))',ERR,ERROR,*999)
      ENDIF
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Adjacent domains :",ERR,ERROR,*999)
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Number of adjacent domains = ", &
        & NODES_MAPPING%NUMBER_OF_ADJACENT_DOMAINS,ERR,ERROR,*999)
      CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,NODES_MAPPING%NUMBER_OF_DOMAINS+1,8,8, &
        & NODES_MAPPING%ADJACENT_DOMAINS_PTR,'("    Adjacent domains ptr  :",8(X,I7))','(27X,8(X,I7))',ERR,ERROR,*999)
      CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,NODES_MAPPING%ADJACENT_DOMAINS_PTR( &
        & NODES_MAPPING%NUMBER_OF_DOMAINS)-1,8,8,NODES_MAPPING%ADJACENT_DOMAINS_LIST, &
        '("    Adjacent domains list :",8(X,I7))','(27X,8(X,I7))',ERR,ERROR,*999)
      DO domain_idx=1,NODES_MAPPING%NUMBER_OF_ADJACENT_DOMAINS
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Adjacent domain idx : ",domain_idx,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Domain number = ", &
          & NODES_MAPPING%ADJACENT_DOMAINS(domain_idx)%DOMAIN_NUMBER,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Number of send ghosts    = ", &
          & NODES_MAPPING%ADJACENT_DOMAINS(domain_idx)%NUMBER_OF_SEND_GHOSTS,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,NODES_MAPPING%ADJACENT_DOMAINS(domain_idx)% &
          & NUMBER_OF_SEND_GHOSTS,6,6,NODES_MAPPING%ADJACENT_DOMAINS(domain_idx)%LOCAL_GHOST_SEND_INDICES, &
          & '("      Local send ghost indicies       :",6(X,I7))','(39X,6(X,I7))',ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Number of recieve ghosts = ", &
          & NODES_MAPPING%ADJACENT_DOMAINS(domain_idx)%NUMBER_OF_RECEIVE_GHOSTS,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,NODES_MAPPING%ADJACENT_DOMAINS(domain_idx)% &
          & NUMBER_OF_RECEIVE_GHOSTS,6,6,NODES_MAPPING%ADJACENT_DOMAINS(domain_idx)%LOCAL_GHOST_RECEIVE_INDICES, &
          & '("      Local receive ghost indicies    :",6(X,I7))','(39X,6(X,I7))',ERR,ERROR,*999)
      ENDDO !domain_idx
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"Dofs mappings :",ERR,ERROR,*999)
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Global to local map :",ERR,ERROR,*999)
      DO ny=1,MESH_TOPOLOGY%DOFS%numberOfDofs
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Global dof = ",ny,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Number of domains  = ", &
          & DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%NUMBER_OF_DOMAINS,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)% &
          & NUMBER_OF_DOMAINS,8,8,DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%LOCAL_NUMBER, &
          & '("      Local number :",8(X,I7))','(20X,8(X,I7))',ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)% &
            & NUMBER_OF_DOMAINS,8,8,DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%DOMAIN_NUMBER, &
            & '("      Domain number:",8(X,I7))','(20X,8(X,I7))',ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)% &
          & NUMBER_OF_DOMAINS,8,8,DOFS_MAPPING%GLOBAL_TO_LOCAL_MAP(ny)%LOCAL_TYPE, &
          & '("      Local type   :",8(X,I7))','(20X,8(X,I7))',ERR,ERROR,*999)
      ENDDO !ny
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Local to global map :",ERR,ERROR,*999)
      DO ny=1,DOFS_MAPPING%TOTAL_NUMBER_OF_LOCAL
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Local dof = ",ny,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Global dof = ", &
          & DOFS_MAPPING%LOCAL_TO_GLOBAL_MAP(ny),ERR,ERROR,*999)
      ENDDO !node_idx
      IF(DIAGNOSTICS2) THEN
        CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Internal dofs :",ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Number of internal dofs = ", &
          & DOFS_MAPPING%NUMBER_OF_INTERNAL,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,DOFS_MAPPING%NUMBER_OF_INTERNAL,8,8, &
          & DOFS_MAPPING%DOMAIN_LIST(DOFS_MAPPING%INTERNAL_START:DOFS_MAPPING%INTERNAL_FINISH), &
          & '("    Internal dofs:",8(X,I7))','(18X,8(X,I7))',ERR,ERROR,*999)
        CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Boundary dofs :",ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Number of boundary dofs = ", &
          & DOFS_MAPPING%NUMBER_OF_BOUNDARY,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,DOFS_MAPPING%NUMBER_OF_BOUNDARY,8,8, &
          & DOFS_MAPPING%DOMAIN_LIST(DOFS_MAPPING%BOUNDARY_START:DOFS_MAPPING%BOUNDARY_FINISH), &
          & '("    Boundary dofs:",8(X,I7))','(18X,8(X,I7))',ERR,ERROR,*999)
        CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Ghost dofs :",ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Number of ghost dofs = ", &
          & DOFS_MAPPING%NUMBER_OF_GHOST,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,DOFS_MAPPING%NUMBER_OF_GHOST,8,8, &
          & DOFS_MAPPING%DOMAIN_LIST(DOFS_MAPPING%GHOST_START:DOFS_MAPPING%GHOST_FINISH), &
          & '("    Ghost dofs   :",8(X,I7))','(18X,8(X,I7))',ERR,ERROR,*999)
      ENDIF
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"  Adjacent domains :",ERR,ERROR,*999)
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Number of adjacent domains = ", &
        & DOFS_MAPPING%NUMBER_OF_ADJACENT_DOMAINS,ERR,ERROR,*999)
      CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,DOFS_MAPPING%NUMBER_OF_DOMAINS+1,8,8, &
        & DOFS_MAPPING%ADJACENT_DOMAINS_PTR,'("    Adjacent domains ptr  :",8(X,I7))','(27X,8(X,I7))',ERR,ERROR,*999)
      CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,DOFS_MAPPING%ADJACENT_DOMAINS_PTR( &
        & DOFS_MAPPING%NUMBER_OF_DOMAINS)-1,8,8,DOFS_MAPPING%ADJACENT_DOMAINS_LIST, &
        '("    Adjacent domains list :",8(X,I7))','(27X,8(X,I7))',ERR,ERROR,*999)
      DO domain_idx=1,DOFS_MAPPING%NUMBER_OF_ADJACENT_DOMAINS
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Adjacent domain idx : ",domain_idx,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Domain number = ", &
          & DOFS_MAPPING%ADJACENT_DOMAINS(domain_idx)%DOMAIN_NUMBER,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Number of send ghosts    = ", &
          & DOFS_MAPPING%ADJACENT_DOMAINS(domain_idx)%NUMBER_OF_SEND_GHOSTS,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,DOFS_MAPPING%ADJACENT_DOMAINS(domain_idx)% &
          & NUMBER_OF_SEND_GHOSTS,6,6,DOFS_MAPPING%ADJACENT_DOMAINS(domain_idx)%LOCAL_GHOST_SEND_INDICES, &
          & '("      Local send ghost indicies       :",6(X,I7))','(39X,6(X,I7))',ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Number of recieve ghosts = ", &
          & DOFS_MAPPING%ADJACENT_DOMAINS(domain_idx)%NUMBER_OF_RECEIVE_GHOSTS,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,DOFS_MAPPING%ADJACENT_DOMAINS(domain_idx)% &
          & NUMBER_OF_RECEIVE_GHOSTS,6,6,DOFS_MAPPING%ADJACENT_DOMAINS(domain_idx)%LOCAL_GHOST_RECEIVE_INDICES, &
          & '("      Local receive ghost indicies    :",6(X,I7))','(39X,6(X,I7))',ERR,ERROR,*999)
      ENDDO !domain_idx
    ENDIF

    EXITS("DOMAIN_MAPPINGS_NODES_DOFS_CALCULATE")
    RETURN
999 IF(ALLOCATED(DOMAINS)) DEALLOCATE(DOMAINS)
    IF(ALLOCATED(ALL_DOMAINS)) DEALLOCATE(ALL_DOMAINS)
    IF(ALLOCATED(GHOST_NODES)) DEALLOCATE(GHOST_NODES)
    IF(ALLOCATED(NUMBER_INTERNAL_NODES)) DEALLOCATE(NUMBER_INTERNAL_NODES)
    IF(ALLOCATED(NUMBER_BOUNDARY_NODES)) DEALLOCATE(NUMBER_BOUNDARY_NODES)
    IF(ASSOCIATED(DOMAIN%MAPPINGS%NODES)) CALL DOMAIN_MAPPINGS_NODES_FINALISE(DOMAIN%MAPPINGS,DUMMY_ERR,DUMMY_ERROR,*998)
998 IF(ASSOCIATED(DOMAIN%MAPPINGS%DOFS)) CALL DOMAIN_MAPPINGS_DOFS_FINALISE(DOMAIN%MAPPINGS,DUMMY_ERR,DUMMY_ERROR,*997)
997 ERRORSEXITS("DOMAIN_MAPPINGS_NODES_DOFS_CALCULATE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DOMAIN_MAPPINGS_NODES_DOFS_CALCULATE


  !
  !================================================================================================================================
  !

  !>Finalises the node mapping in the given domain mappings. \todo pass in the nodes mapping
  SUBROUTINE DOMAIN_MAPPINGS_NODES_FINALISE(DOMAIN_MAPPINGS,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_MAPPINGS_TYPE), POINTER :: DOMAIN_MAPPINGS !<A pointer to the domain mapping to finalise the nodes for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_MAPPINGS_NODES_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(DOMAIN_MAPPINGS)) THEN
      IF(ASSOCIATED(DOMAIN_MAPPINGS%NODES)) THEN
        CALL DOMAIN_MAPPINGS_MAPPING_FINALISE(DOMAIN_MAPPINGS%NODES,ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Domain mapping is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_MAPPINGS_NODES_FINALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_MAPPINGS_NODES_FINALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DOMAIN_MAPPINGS_NODES_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the node mapping in the given domain mapping. \todo finalise on error
  SUBROUTINE DOMAIN_MAPPINGS_NODES_INITIALISE(DOMAIN_MAPPINGS,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_MAPPINGS_TYPE), POINTER :: DOMAIN_MAPPINGS !<A pointer to the domain mappings to initialise the nodes for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_MAPPINGS_NODES_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(DOMAIN_MAPPINGS)) THEN
      IF(ASSOCIATED(DOMAIN_MAPPINGS%NODES)) THEN
        CALL FlagError("Domain nodes mappings are already associated.",ERR,ERROR,*999)
      ELSE
        ALLOCATE(DOMAIN_MAPPINGS%NODES,STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate domain mappings nodes.",ERR,ERROR,*999)
        CALL DOMAIN_MAPPINGS_MAPPING_INITIALISE(DOMAIN_MAPPINGS%NODES,DOMAIN_MAPPINGS%DOMAIN%DECOMPOSITION%NUMBER_OF_DOMAINS, &
          & ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Domain mapping is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_MAPPINGS_NODES_INITIALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_MAPPINGS_NODES_INITIALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DOMAIN_MAPPINGS_NODES_INITIALISE

  !
  !================================================================================================================================
  !

  !>Initialises the assignment of global face numbers
  SUBROUTINE DomainTopology_AssignGlobalFacesInitialise(domain,err,error,*)

    !Argument variables
    TYPE(DOMAIN_TYPE), POINTER :: domain !<A pointer to the domain topology to initialise the dofs for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: startNic, elementGlobalNo, componentIdx
    TYPE(MESH_TYPE), POINTER :: mesh
    TYPE(MeshComponentTopologyType), POINTER :: topology

    ENTERS("DomainTopology_AssignGlobalFacesInitialise",err,error,*999)

    IF(.NOT.ASSOCIATED(domain)) CALL FlagError("domain is not associated.",err,error,*999)
    IF(.NOT.ASSOCIATED(domain%mesh)) CALL FlagError("domain%mesh is not associated.",err,error,*999)
    mesh=>domain%mesh
    componentIdx=domain%MESH_COMPONENT_NUMBER
    topology=>mesh%topology(componentIdx)%PTR

    SELECT CASE(topology%ELEMENTS%ELEMENTS(1)%BASIS%TYPE)!Assumes all elements have the same basis
    CASE(BASIS_SIMPLEX_TYPE)
      startNic=1
    CASE(BASIS_LAGRANGE_HERMITE_TP_TYPE)
      startNic=-topology%ELEMENTS%ELEMENTS(1)%BASIS%NUMBER_OF_XI_COORDINATES
    CASE DEFAULT
      !do nothing
    END SELECT

    DO elementGlobalNo = 1,topology%ELEMENTS%NUMBER_OF_ELEMENTS
      ALLOCATE(topology%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_FACES(startNic:topology%ELEMENTS% &
        & ELEMENTS(elementGlobalNo)%BASIS%NUMBER_OF_XI_COORDINATES),STAT=err)
      IF(err/=0) CALL FlagError("Could not allocate topology%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_FACES", &
      & err,error,*999)
      topology%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_FACES=0
    ENDDO

    EXITS("DomainTopology_AssignGlobalFacesInitialise")
    RETURN
999 ERRORSEXITS("DomainTopology_AssignGlobalFacesInitialise",err,error)
    RETURN 1
  END SUBROUTINE DomainTopology_AssignGlobalFacesInitialise

  !
  !================================================================================================================================
  !

  !>Initialises the assignment of global line numbers
  SUBROUTINE DomainTopology_AssignGlobalLinesInitialise(domain,err,error,*)

    !Argument variables
    TYPE(DOMAIN_TYPE), POINTER :: domain !<A pointer to the domain topology to initialise the dofs for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: startNic, elementGlobalNo, componentIdx
    TYPE(MESH_TYPE), POINTER :: mesh
    TYPE(MeshComponentTopologyType), POINTER :: topology

    ENTERS("DomainTopology_AssignGlobalLinesInitialise",err,error,*999)

    IF(.NOT.ASSOCIATED(domain)) CALL FlagError("domain is not associated.",err,error,*999)
    IF(.NOT.ASSOCIATED(domain%mesh)) CALL FlagError("domain%mesh is not associated.",err,error,*999)
    mesh=>domain%mesh
    componentIdx=domain%MESH_COMPONENT_NUMBER
    topology=>mesh%topology(componentIdx)%PTR

    SELECT CASE(topology%ELEMENTS%ELEMENTS(1)%BASIS%TYPE)!Assumes all elements have the same basis
    CASE(BASIS_SIMPLEX_TYPE)
      startNic=1
    CASE(BASIS_LAGRANGE_HERMITE_TP_TYPE)
      IF(domain%number_of_dimensions == 1) THEN
        startNic=1
      ELSE
        startNic=-topology%ELEMENTS%ELEMENTS(1)%BASIS%NUMBER_OF_XI_COORDINATES
      END IF
    CASE DEFAULT
      !do nothing
    END SELECT

    DO elementGlobalNo = 1,topology%ELEMENTS%NUMBER_OF_ELEMENTS
      ALLOCATE(topology%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_LINES(startNic:topology%ELEMENTS% &
        & ELEMENTS(elementGlobalNo)%BASIS%NUMBER_OF_XI_COORDINATES),STAT=err)
      IF(err/=0) CALL FlagError("Could not allocate topology%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_LINES", &
      & err,error,*999)
      topology%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_LINES=0
    ENDDO

    EXITS("DomainTopology_AssignGlobalLinesInitialise")
    RETURN
999 ERRORSEXITS("DomainTopology_AssignGlobalLinesInitialise",err,error)
    RETURN 1
  END SUBROUTINE DomainTopology_AssignGlobalLinesInitialise

  !
  !================================================================================================================================
  !

  !>Finalises the assignment of global face numbers
  SUBROUTINE DomainTopology_AssignGlobalFacesFinalise(domain,err,error,*)

    !Argument variables
    TYPE(DOMAIN_TYPE), POINTER :: domain !<A pointer to the domain topology to initialise the dofs for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: componentIdx, elementGlobalNo, faceGlobalNo

    ENTERS("DomainTopology_AssignGlobalFacesFinalise",err,error,*999)

    IF(.NOT.ASSOCIATED(domain)) CALL FlagError("domain is not associated.",err,error,*999)
    IF(.NOT.ASSOCIATED(domain%mesh)) CALL FlagError("domain%mesh is not associated.",err,error,*999)
    componentIdx=domain%MESH_COMPONENT_NUMBER

    DO elementGlobalNo = 1,domain%mesh%topology(componentIdx)%PTR%ELEMENTS%NUMBER_OF_ELEMENTS
      IF(ALLOCATED(domain%mesh%topology(componentIdx)%PTR%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_FACES)) THEN
        DEALLOCATE(domain%mesh%topology(componentIdx)%PTR%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_FACES)
      ELSE
        CALL FlagError("topology%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_FACES is not associated",err,error,*999)
      ENDIF
    ENDDO

    DO faceGlobalNo=1,domain%mesh%topology(componentIdx)%PTR%faces%numberOfFaces
      IF(ASSOCIATED(domain%mesh%topology(componentIdx)%PTR%faces%faces(faceGlobalNo)%surroundingElements)) THEN
        DEALLOCATE(domain%mesh%topology(componentIdx)%PTR%faces%faces(faceGlobalNo)%surroundingElements)
      ENDIF
    ENDDO
    IF(ALLOCATED(domain%mesh%topology(componentIdx)%PTR%faces%faces)) DEALLOCATE(domain%mesh%topology(componentIdx)%PTR%faces%faces)
    IF(ASSOCIATED(domain%mesh%topology(componentIdx)%PTR%faces)) DEALLOCATE(domain%mesh%topology(componentIdx)%PTR%faces)



    EXITS("DomainTopology_AssignGlobalFacesFinalise")
    RETURN
999 ERRORSEXITS("DomainTopology_AssignGlobalFacesFinalise",err,error)
    RETURN 1
  END SUBROUTINE DomainTopology_AssignGlobalFacesFinalise

  !
  !================================================================================================================================
  !

  !>Finalises the assignment of global line numbers
  SUBROUTINE DomainTopology_AssignGlobalLinesFinalise(domain,err,error,*)

    !Argument variables
    TYPE(DOMAIN_TYPE), POINTER :: domain !<A pointer to the domain topology to initialise the dofs for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: componentIdx, elementGlobalNo, lineGlobalNo

    ENTERS("DomainTopology_AssignGlobalLinesFinalise",err,error,*999)

    IF(.NOT.ASSOCIATED(domain)) CALL FlagError("domain is not associated.",err,error,*999)
    IF(.NOT.ASSOCIATED(domain%mesh)) CALL FlagError("domain%mesh is not associated.",err,error,*999)
    componentIdx=domain%MESH_COMPONENT_NUMBER

    DO elementGlobalNo = 1,domain%mesh%topology(componentIdx)%PTR%ELEMENTS%NUMBER_OF_ELEMENTS
      IF(ALLOCATED(domain%mesh%topology(componentIdx)%PTR%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_LINES)) THEN
        DEALLOCATE(domain%mesh%topology(componentIdx)%PTR%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_LINES)
      ELSE
        CALL FlagError("topology%ELEMENTS%ELEMENTS(elementGlobalNo)%GLOBAL_ELEMENT_LINES is not associated",err,error,*999)
      ENDIF
    ENDDO

    DO lineGlobalNo=1,domain%mesh%topology(componentIdx)%PTR%lines%numberOfLines
      IF(ASSOCIATED(domain%mesh%topology(componentIdx)%PTR%lines%lines(lineGlobalNo)%surroundingElements)) THEN
        DEALLOCATE(domain%mesh%topology(componentIdx)%PTR%lines%lines(lineGlobalNo)%surroundingElements)
      ENDIF
    ENDDO
    IF(ALLOCATED(domain%mesh%topology(componentIdx)%PTR%lines%lines)) DEALLOCATE(domain%mesh%topology(componentIdx)%PTR%lines%lines)
    IF(ASSOCIATED(domain%mesh%topology(componentIdx)%PTR%lines)) DEALLOCATE(domain%mesh%topology(componentIdx)%PTR%lines)



    EXITS("DomainTopology_AssignGlobalLinesFinalise")
    RETURN
999 ERRORSEXITS("DomainTopology_AssignGlobalLinesFinalise",err,error)
    RETURN 1
  END SUBROUTINE DomainTopology_AssignGlobalLinesFinalise

  !
  !================================================================================================================================
  !

  !>Calculates the domain topology.
  SUBROUTINE DOMAIN_TOPOLOGY_CALCULATE(TOPOLOGY,ERR,ERROR,*)

   !Argument variables
    TYPE(DOMAIN_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the domain topology to calculate.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: ne,np
    TYPE(BASIS_TYPE), POINTER :: BASIS

    ENTERS("DOMAIN_TOPOLOGY_CALCULATE",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      !Find maximum number of element parameters for all elements in the domain toplogy
      TOPOLOGY%ELEMENTS%MAXIMUM_NUMBER_OF_ELEMENT_PARAMETERS=-1
      DO ne=1,TOPOLOGY%ELEMENTS%TOTAL_NUMBER_OF_ELEMENTS
        BASIS=>TOPOLOGY%ELEMENTS%ELEMENTS(ne)%BASIS
        IF(ASSOCIATED(BASIS)) THEN
          IF(BASIS%NUMBER_OF_ELEMENT_PARAMETERS>TOPOLOGY%ELEMENTS%MAXIMUM_NUMBER_OF_ELEMENT_PARAMETERS) &
            & TOPOLOGY%ELEMENTS%MAXIMUM_NUMBER_OF_ELEMENT_PARAMETERS=BASIS%NUMBER_OF_ELEMENT_PARAMETERS
        ELSE
          CALL FlagError("Basis is not associated.",ERR,ERROR,*999)
        ENDIF
      ENDDO !ne
      !Find maximum number of derivatives for all nodes in the domain toplogy
      TOPOLOGY%NODES%MAXIMUM_NUMBER_OF_DERIVATIVES=-1
      DO np=1,TOPOLOGY%NODES%TOTAL_NUMBER_OF_NODES
        IF(TOPOLOGY%NODES%NODES(np)%NUMBER_OF_DERIVATIVES>TOPOLOGY%NODES%MAXIMUM_NUMBER_OF_DERIVATIVES) &
            & TOPOLOGY%NODES%MAXIMUM_NUMBER_OF_DERIVATIVES=TOPOLOGY%NODES%NODES(np)%NUMBER_OF_DERIVATIVES
      ENDDO !np
      !Calculate the elements surrounding the nodes in the domain topology
      CALL DomainTopology_NodesSurroundingElementsCalculate(TOPOLOGY,ERR,ERROR,*999)
    ELSE
      CALL FlagError("Topology is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_TOPOLOGY_CALCULATE")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_CALCULATE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DOMAIN_TOPOLOGY_CALCULATE

  !
  !================================================================================================================================
  !

  !>Initialises the local domain topology from the mesh topology.
  SUBROUTINE DOMAIN_TOPOLOGY_INITIALISE_FROM_MESH(DOMAIN,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_TYPE), POINTER :: DOMAIN !<A pointer to the domain to initialise the domain topology from the mesh topology for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: local_element,global_element,local_node,global_node,version_idx,derivative_idx,node_idx,dof_idx, &
      & component_idx
    INTEGER(INTG) :: ne,nn,nkk,INSERT_STATUS
    LOGICAL :: FOUND
    TYPE(BASIS_TYPE), POINTER :: BASIS
    TYPE(MESH_TYPE), POINTER :: MESH
    TYPE(DOMAIN_ELEMENTS_TYPE), POINTER :: DOMAIN_ELEMENTS
    TYPE(MeshElementsType), POINTER :: MESH_ELEMENTS
    TYPE(DOMAIN_NODES_TYPE), POINTER :: DOMAIN_NODES
    TYPE(MeshNodesType), POINTER :: MESH_NODES
    TYPE(DOMAIN_DOFS_TYPE), POINTER :: DOMAIN_DOFS

    ENTERS("DOMAIN_TOPOLOGY_INITIALISE_FROM_MESH",ERR,ERROR,*999)

    IF(ASSOCIATED(DOMAIN)) THEN
      IF(ASSOCIATED(DOMAIN%TOPOLOGY)) THEN
        IF(ASSOCIATED(DOMAIN%MAPPINGS)) THEN
          IF(ASSOCIATED(DOMAIN%MESH)) THEN
            MESH=>DOMAIN%MESH
            component_idx=DOMAIN%MESH_COMPONENT_NUMBER
            IF(ASSOCIATED(MESH%TOPOLOGY(component_idx)%PTR)) THEN
              MESH_ELEMENTS=>MESH%TOPOLOGY(component_idx)%PTR%ELEMENTS
              DOMAIN_ELEMENTS=>DOMAIN%TOPOLOGY%ELEMENTS
              MESH_NODES=>MESH%TOPOLOGY(component_idx)%PTR%NODES
              DOMAIN_NODES=>DOMAIN%TOPOLOGY%NODES
              DOMAIN_DOFS=>DOMAIN%TOPOLOGY%DOFS
              ALLOCATE(DOMAIN_ELEMENTS%ELEMENTS(DOMAIN%MAPPINGS%ELEMENTS%TOTAL_NUMBER_OF_LOCAL),STAT=ERR)
              IF(ERR/=0) CALL FlagError("Could not allocate domain elements elements.",ERR,ERROR,*999)
              DOMAIN_ELEMENTS%NUMBER_OF_ELEMENTS=DOMAIN%MAPPINGS%ELEMENTS%NUMBER_OF_LOCAL
              DOMAIN_ELEMENTS%TOTAL_NUMBER_OF_ELEMENTS=DOMAIN%MAPPINGS%ELEMENTS%TOTAL_NUMBER_OF_LOCAL
              DOMAIN_ELEMENTS%NUMBER_OF_GLOBAL_ELEMENTS=DOMAIN%MAPPINGS%ELEMENTS%NUMBER_OF_GLOBAL
              ALLOCATE(DOMAIN_NODES%NODES(DOMAIN%MAPPINGS%NODES%TOTAL_NUMBER_OF_LOCAL),STAT=ERR)
              IF(ERR/=0) CALL FlagError("Could not allocate domain nodes nodes.",ERR,ERROR,*999)
              DOMAIN_NODES%NUMBER_OF_NODES=DOMAIN%MAPPINGS%NODES%NUMBER_OF_LOCAL
              DOMAIN_NODES%TOTAL_NUMBER_OF_NODES=DOMAIN%MAPPINGS%NODES%TOTAL_NUMBER_OF_LOCAL
              DOMAIN_NODES%NUMBER_OF_GLOBAL_NODES=DOMAIN%MAPPINGS%NODES%NUMBER_OF_GLOBAL
              ALLOCATE(DOMAIN_DOFS%DOF_INDEX(3,DOMAIN%MAPPINGS%DOFS%TOTAL_NUMBER_OF_LOCAL),STAT=ERR)
              IF(ERR/=0) CALL FlagError("Could not allocate domain dofs dof index.",ERR,ERROR,*999)
              DOMAIN_DOFS%NUMBER_OF_DOFS=DOMAIN%MAPPINGS%DOFS%NUMBER_OF_LOCAL
              DOMAIN_DOFS%TOTAL_NUMBER_OF_DOFS=DOMAIN%MAPPINGS%DOFS%TOTAL_NUMBER_OF_LOCAL
              DOMAIN_DOFS%NUMBER_OF_GLOBAL_DOFS=DOMAIN%MAPPINGS%DOFS%NUMBER_OF_GLOBAL
              !Loop over the domain nodes and calculate the parameters from the mesh nodes
              CALL TREE_CREATE_START(DOMAIN_NODES%NODES_TREE,ERR,ERROR,*999)
              CALL TREE_INSERT_TYPE_SET(DOMAIN_NODES%NODES_TREE,TREE_NO_DUPLICATES_ALLOWED,ERR,ERROR,*999)
              CALL TREE_CREATE_FINISH(DOMAIN_NODES%NODES_TREE,ERR,ERROR,*999)
              dof_idx=0
              DO local_node=1,DOMAIN_NODES%TOTAL_NUMBER_OF_NODES
                CALL DOMAIN_TOPOLOGY_NODE_INITIALISE(DOMAIN_NODES%NODES(local_node),ERR,ERROR,*999)
                global_node=DOMAIN%MAPPINGS%NODES%LOCAL_TO_GLOBAL_MAP(local_node)
                DOMAIN_NODES%NODES(local_node)%LOCAL_NUMBER=local_node
                DOMAIN_NODES%NODES(local_node)%MESH_NUMBER=global_node
                DOMAIN_NODES%NODES(local_node)%GLOBAL_NUMBER=MESH_NODES%NODES(global_node)%globalNumber
                DOMAIN_NODES%NODES(local_node)%USER_NUMBER=MESH_NODES%NODES(global_node)%userNumber
                CALL TREE_ITEM_INSERT(DOMAIN_NODES%NODES_TREE,DOMAIN_NODES%NODES(local_node)%USER_NUMBER,local_node, &
                  & INSERT_STATUS,ERR,ERROR,*999)
                DOMAIN_NODES%NODES(local_node)%NUMBER_OF_SURROUNDING_ELEMENTS=0
                NULLIFY(DOMAIN_NODES%NODES(local_node)%SURROUNDING_ELEMENTS)
                DOMAIN_NODES%NODES(local_node)%NUMBER_OF_DERIVATIVES=MESH_NODES%NODES(global_node)%numberOfDerivatives
                ALLOCATE(DOMAIN_NODES%NODES(local_node)%DERIVATIVES(MESH_NODES%NODES(global_node)%numberOfDerivatives),STAT=ERR)
                IF(ERR/=0) CALL FlagError("Could not allocate domain node derivatives.",ERR,ERROR,*999)
                DO derivative_idx=1,DOMAIN_NODES%NODES(local_node)%NUMBER_OF_DERIVATIVES
                  CALL DOMAIN_TOPOLOGY_NODE_DERIVATIVE_INITIALISE( &
                    & DOMAIN_NODES%NODES(local_node)%DERIVATIVES(derivative_idx),ERR,ERROR,*999)
                  DOMAIN_NODES%NODES(local_node)%DERIVATIVES(derivative_idx)%GLOBAL_DERIVATIVE_INDEX= &
                    & MESH_NODES%NODES(global_node)%DERIVATIVES(derivative_idx)%globalDerivativeIndex
                  DOMAIN_NODES%NODES(local_node)%DERIVATIVES(derivative_idx)%PARTIAL_DERIVATIVE_INDEX= &
                    & MESH_NODES%NODES(global_node)%DERIVATIVES(derivative_idx)%partialDerivativeIndex
                  DOMAIN_NODES%NODES(local_node)%DERIVATIVES(derivative_idx)%numberOfVersions= &
                    & MESH_NODES%NODES(global_node)%DERIVATIVES(derivative_idx)%numberOfVersions
                  ALLOCATE(DOMAIN_NODES%NODES(local_node)%DERIVATIVES(derivative_idx)%userVersionNumbers( &
                    & MESH_NODES%NODES(global_node)%DERIVATIVES(derivative_idx)%numberOfVersions),STAT=ERR)
                  IF(ERR/=0) CALL FlagError("Could not allocate node derivative version numbers.",ERR,ERROR,*999)
                  DOMAIN_NODES%NODES(local_node)%DERIVATIVES(derivative_idx)%userVersionNumbers(1: &
                    & MESH_NODES%NODES(global_node)%DERIVATIVES(derivative_idx)%numberOfVersions)= &
                    & MESH_NODES%NODES(global_node)%DERIVATIVES(derivative_idx)%userVersionNumbers(1: &
                    & MESH_NODES%NODES(global_node)%DERIVATIVES(derivative_idx)%numberOfVersions)
                  ALLOCATE(DOMAIN_NODES%NODES(local_node)%DERIVATIVES(derivative_idx)%DOF_INDEX( &
                    & MESH_NODES%NODES(global_node)%DERIVATIVES(derivative_idx)%numberOfVersions),STAT=ERR)
                  IF(ERR/=0) CALL FlagError("Could not allocate node dervative versions dof index.",ERR,ERROR,*999)
                  DO version_idx=1,DOMAIN_NODES%NODES(local_node)%DERIVATIVES(derivative_idx)%numberOfVersions
                    dof_idx=dof_idx+1
                    DOMAIN_NODES%NODES(local_node)%DERIVATIVES(derivative_idx)%DOF_INDEX(version_idx)=dof_idx
                    DOMAIN_DOFS%DOF_INDEX(1,dof_idx)=version_idx
                    DOMAIN_DOFS%DOF_INDEX(2,dof_idx)=derivative_idx
                    DOMAIN_DOFS%DOF_INDEX(3,dof_idx)=local_node
                  ENDDO !version_idx
                ENDDO !derivative_idx
                DOMAIN_NODES%NODES(local_node)%BOUNDARY_NODE=MESH_NODES%NODES(global_node)%boundaryNode
              ENDDO !local_node
              !Loop over the domain elements and renumber from the mesh elements
              DO local_element=1,DOMAIN_ELEMENTS%TOTAL_NUMBER_OF_ELEMENTS
                CALL DOMAIN_TOPOLOGY_ELEMENT_INITIALISE(DOMAIN_ELEMENTS%ELEMENTS(local_element),ERR,ERROR,*999)
                global_element=DOMAIN%MAPPINGS%ELEMENTS%LOCAL_TO_GLOBAL_MAP(local_element)
                BASIS=>MESH_ELEMENTS%ELEMENTS(global_element)%BASIS
                DOMAIN_ELEMENTS%ELEMENTS(local_element)%NUMBER=local_element
                DOMAIN_ELEMENTS%ELEMENTS(local_element)%BASIS=>BASIS
                ALLOCATE(DOMAIN_ELEMENTS%ELEMENTS(local_element)%ELEMENT_NODES(BASIS%NUMBER_OF_NODES),STAT=ERR)
                IF(ERR/=0) CALL FlagError("Could not allocate domain elements element nodes.",ERR,ERROR,*999)
                ALLOCATE(DOMAIN_ELEMENTS%ELEMENTS(local_element)%ELEMENT_DERIVATIVES(BASIS%MAXIMUM_NUMBER_OF_DERIVATIVES, &
                  & BASIS%NUMBER_OF_NODES),STAT=ERR)
                IF(ERR/=0) CALL FlagError("Could not allocate domain elements element derivatives.",ERR,ERROR,*999)
                ALLOCATE(DOMAIN_ELEMENTS%ELEMENTS(local_element)%elementVersions(BASIS%MAXIMUM_NUMBER_OF_DERIVATIVES, &
                  & BASIS%NUMBER_OF_NODES),STAT=ERR)
                IF(ERR/=0) CALL FlagError("Could not allocate domain elements element versions.",ERR,ERROR,*999)
                DO nn=1,BASIS%NUMBER_OF_NODES
                  global_node=MESH_ELEMENTS%ELEMENTS(global_element)%MESH_ELEMENT_NODES(nn)
                  local_node=DOMAIN%MAPPINGS%NODES%GLOBAL_TO_LOCAL_MAP(global_node)%LOCAL_NUMBER(1)
                  DOMAIN_ELEMENTS%ELEMENTS(local_element)%ELEMENT_NODES(nn)=local_node
                  DO derivative_idx=1,BASIS%NUMBER_OF_DERIVATIVES(nn)
                    !Find equivalent node derivative by matching partial derivative index
                    !/todo Take a look at this - is it needed any more?
                    FOUND=.FALSE.
                    DO nkk=1,DOMAIN_NODES%NODES(local_node)%NUMBER_OF_DERIVATIVES
                      IF(DOMAIN_NODES%NODES(local_node)%DERIVATIVES(nkk)%PARTIAL_DERIVATIVE_INDEX == &
                        & BASIS%PARTIAL_DERIVATIVE_INDEX(derivative_idx,nn)) THEN
                        FOUND=.TRUE.
                        EXIT
                      ENDIF
                    ENDDO !nkk
                    IF(FOUND) THEN
                      DOMAIN_ELEMENTS%ELEMENTS(local_element)%ELEMENT_DERIVATIVES(derivative_idx,nn)=nkk
                      DOMAIN_ELEMENTS%ELEMENTS(local_element)%elementVersions(derivative_idx,nn) = &
                        & MESH_ELEMENTS%ELEMENTS(global_element)%USER_ELEMENT_NODE_VERSIONS(derivative_idx,nn)
                    ELSE
                      CALL FlagError("Could not find equivalent node derivative",ERR,ERROR,*999)
                    ENDIF
                  ENDDO !derivative_idx
                ENDDO !nn
              ENDDO !local_element
            ELSE
              CALL FlagError("Mesh topology is not associated",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Mesh is not associated",ERR,ERROR,*999)

          ENDIF
        ELSE
          CALL FlagError("Domain mapping is not associated",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Domain topology is not associated",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Domain is not associated",ERR,ERROR,*999)
    ENDIF

    IF(DIAGNOSTICS1) THEN
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"Initialised domain topology :",ERR,ERROR,*999)
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  Total number of domain nodes = ",DOMAIN_NODES%TOTAL_NUMBER_OF_NODES, &
        & ERR,ERROR,*999)
      DO node_idx=1,DOMAIN_NODES%TOTAL_NUMBER_OF_NODES
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Node number = ",DOMAIN_NODES%NODES(node_idx)%LOCAL_NUMBER, &
          & ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Node mesh number = ",DOMAIN_NODES%NODES(node_idx)%MESH_NUMBER, &
          & ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Node global number = ",DOMAIN_NODES%NODES(node_idx)%GLOBAL_NUMBER, &
          & ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Node user number = ",DOMAIN_NODES%NODES(node_idx)%USER_NUMBER, &
          & ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Number of derivatives = ", &
          & DOMAIN_NODES%NODES(node_idx)%NUMBER_OF_DERIVATIVES,ERR,ERROR,*999)
        DO derivative_idx=1,DOMAIN_NODES%NODES(local_node)%NUMBER_OF_DERIVATIVES
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Node local derivative number = ",derivative_idx,ERR,ERROR,*999)
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"        Global derivative index = ", &
            & DOMAIN_NODES%NODES(node_idx)%DERIVATIVES(derivative_idx)%GLOBAL_DERIVATIVE_INDEX,ERR,ERROR,*999)
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"        Partial derivative index = ", &
            & DOMAIN_NODES%NODES(node_idx)%DERIVATIVES(derivative_idx)%PARTIAL_DERIVATIVE_INDEX,ERR,ERROR,*999)
          CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1, &
            & DOMAIN_NODES%NODES(node_idx)%DERIVATIVES(derivative_idx)%numberOfVersions,4,4, &
            & DOMAIN_NODES%NODES(node_idx)%DERIVATIVES(derivative_idx)%DOF_INDEX, &
            & '("        Degree-of-freedom index(version_idx)  :",4(X,I9))','(36X,4(X,I9))',ERR,ERROR,*999)
        ENDDO !derivative_idx
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Boundary node = ", &
          & DOMAIN_NODES%NODES(node_idx)%BOUNDARY_NODE,ERR,ERROR,*999)
     ENDDO !node_idx
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  Total Number of domain dofs = ",DOMAIN_DOFS%TOTAL_NUMBER_OF_DOFS, &
        & ERR,ERROR,*999)
      DO dof_idx=1,DOMAIN_DOFS%TOTAL_NUMBER_OF_DOFS
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Dof number = ",dof_idx,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,3,3,3, &
          & DOMAIN_DOFS%DOF_INDEX(:,dof_idx),'("    Degree-of-freedom index :",3(X,I9))','(29X,3(X,I9))', &
          & ERR,ERROR,*999)
      ENDDO !dof_idx
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  Total number of domain elements = ", &
        & DOMAIN_ELEMENTS%TOTAL_NUMBER_OF_ELEMENTS,ERR,ERROR,*999)
      DO ne=1,DOMAIN_ELEMENTS%TOTAL_NUMBER_OF_ELEMENTS
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  Element number = ",DOMAIN_ELEMENTS%ELEMENTS(ne)%NUMBER,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Basis user number = ", &
          & DOMAIN_ELEMENTS%ELEMENTS(ne)%BASIS%USER_NUMBER,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Number of local nodes = ", &
          & DOMAIN_ELEMENTS%ELEMENTS(ne)%BASIS%NUMBER_OF_NODES,ERR,ERROR,*999)
        CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,DOMAIN_ELEMENTS%ELEMENTS(ne)%BASIS%NUMBER_OF_NODES,8,8, &
          & DOMAIN_ELEMENTS%ELEMENTS(ne)%ELEMENT_NODES,'("    Element nodes(nn) :",8(X,I9))','(23X,8(X,I9))', &
          & ERR,ERROR,*999)
        DO nn=1,DOMAIN_ELEMENTS%ELEMENTS(ne)%BASIS%NUMBER_OF_NODES
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Local node number : ",nn,ERR,ERROR,*999)
          CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,DOMAIN_ELEMENTS%ELEMENTS(ne)%BASIS%NUMBER_OF_DERIVATIVES(nn),8,8, &
            & DOMAIN_ELEMENTS%ELEMENTS(ne)%ELEMENT_DERIVATIVES(:,nn), &
            & '("        Element derivatives :",8(X,I2))','(29X,8(X,I2))',ERR,ERROR,*999)
          CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,DOMAIN_ELEMENTS%ELEMENTS(ne)%BASIS%NUMBER_OF_DERIVATIVES(nn),8,8, &
            & DOMAIN_ELEMENTS%ELEMENTS(ne)%elementVersions(:,nn), &
            & '("        Element versions    :",8(X,I2))','(29X,8(X,I2))',ERR,ERROR,*999)
        ENDDO !nn
      ENDDO !ne
    ENDIF

    EXITS("DOMAIN_TOPOLOGY_INITIALISE_FROM_MESH")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_INITIALISE_FROM_MESH",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DOMAIN_TOPOLOGY_INITIALISE_FROM_MESH

  !
  !================================================================================================================================
  !

  !>Finalises the dofs in the given domain topology. \todo pass in the dofs topolgy
  SUBROUTINE DOMAIN_TOPOLOGY_DOFS_FINALISE(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the domain topology to finalise the dofs for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_TOPOLOGY_DOFS_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      IF(ASSOCIATED(TOPOLOGY%DOFS)) THEN
        IF(ALLOCATED(TOPOLOGY%DOFS%DOF_INDEX)) DEALLOCATE(TOPOLOGY%DOFS%DOF_INDEX)
        DEALLOCATE(TOPOLOGY%DOFS)
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_TOPOLOGY_DOFS_FINALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_DOFS_FINALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DOMAIN_TOPOLOGY_DOFS_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the dofs data structures for a domain topology. \todo finalise on exit
  SUBROUTINE DOMAIN_TOPOLOGY_DOFS_INITIALISE(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the domain topology to initialise the dofs for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_TOPOLOGY_DOFS_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      IF(ASSOCIATED(TOPOLOGY%DOFS)) THEN
        CALL FlagError("Decomposition already has topology dofs associated",ERR,ERROR,*999)
      ELSE
        ALLOCATE(TOPOLOGY%DOFS,STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate topology dofs",ERR,ERROR,*999)
        TOPOLOGY%DOFS%NUMBER_OF_DOFS=0
        TOPOLOGY%DOFS%TOTAL_NUMBER_OF_DOFS=0
        TOPOLOGY%DOFS%NUMBER_OF_GLOBAL_DOFS=0
        TOPOLOGY%DOFS%DOMAIN=>TOPOLOGY%DOMAIN
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_TOPOLOGY_DOFS_INITIALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_DOFS_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DOMAIN_TOPOLOGY_DOFS_INITIALISE

  !
  !================================================================================================================================
  !

  !>Finalises the given domain topology element.
  SUBROUTINE DOMAIN_TOPOLOGY_ELEMENT_FINALISE(ELEMENT,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_ELEMENT_TYPE) :: ELEMENT !<The domain element to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_TOPOLOGY_ELEMENT_FINALISE",ERR,ERROR,*999)

    IF(ALLOCATED(ELEMENT%ELEMENT_NODES)) DEALLOCATE(ELEMENT%ELEMENT_NODES)
    IF(ALLOCATED(ELEMENT%ELEMENT_DERIVATIVES)) DEALLOCATE(ELEMENT%ELEMENT_DERIVATIVES)
    IF(ALLOCATED(ELEMENT%elementVersions)) DEALLOCATE(ELEMENT%elementVersions)

    EXITS("DOMAIN_TOPOLOGY_ELEMENT_FINALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_ELEMENT_FINALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DOMAIN_TOPOLOGY_ELEMENT_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the given domain topology element.
  SUBROUTINE DOMAIN_TOPOLOGY_ELEMENT_INITIALISE(ELEMENT,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_ELEMENT_TYPE) :: ELEMENT !<The domain element to initialise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_TOPOLOGY_ELEMENT_INITIALISE",ERR,ERROR,*999)

    ELEMENT%NUMBER=0
    NULLIFY(ELEMENT%BASIS)

    EXITS("DOMAIN_TOPOLOGY_ELEMENT_INITIALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_ELEMENT_INITIALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DOMAIN_TOPOLOGY_ELEMENT_INITIALISE

  !
  !================================================================================================================================
  !

  !>Finalises the elements in the given domain topology. \todo pass in the domain elements
  SUBROUTINE DOMAIN_TOPOLOGY_ELEMENTS_FINALISE(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the domain topology to finalise the elements for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: ne

    ENTERS("DOMAIN_TOPOLOGY_ELEMENTS_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      IF(ASSOCIATED(TOPOLOGY%ELEMENTS)) THEN
        DO ne=1,TOPOLOGY%ELEMENTS%TOTAL_NUMBER_OF_ELEMENTS
          CALL DOMAIN_TOPOLOGY_ELEMENT_FINALISE(TOPOLOGY%ELEMENTS%ELEMENTS(ne),ERR,ERROR,*999)
        ENDDO !ne
        IF(ASSOCIATED(TOPOLOGY%ELEMENTS%ELEMENTS)) DEALLOCATE(TOPOLOGY%ELEMENTS%ELEMENTS)
        DEALLOCATE(TOPOLOGY%ELEMENTS)
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_TOPOLOGY_ELEMENTS_FINALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_ELEMENTS_FINALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DOMAIN_TOPOLOGY_ELEMENTS_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the element data structures for a domain topology. \todo finalise on error
  SUBROUTINE DOMAIN_TOPOLOGY_ELEMENTS_INITIALISE(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the domain topology to initialise the elements for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_TOPOLOGY_ELEMENTS_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      IF(ASSOCIATED(TOPOLOGY%ELEMENTS)) THEN
        CALL FlagError("Domain already has topology elements associated",ERR,ERROR,*999)
      ELSE
        ALLOCATE(TOPOLOGY%ELEMENTS,STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate topology elements",ERR,ERROR,*999)
        TOPOLOGY%ELEMENTS%NUMBER_OF_ELEMENTS=0
        TOPOLOGY%ELEMENTS%TOTAL_NUMBER_OF_ELEMENTS=0
        TOPOLOGY%ELEMENTS%NUMBER_OF_GLOBAL_ELEMENTS=0
        TOPOLOGY%ELEMENTS%DOMAIN=>TOPOLOGY%DOMAIN
        NULLIFY(TOPOLOGY%ELEMENTS%ELEMENTS)
        TOPOLOGY%ELEMENTS%MAXIMUM_NUMBER_OF_ELEMENT_PARAMETERS=0
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_TOPOLOGY_ELEMENTS_INITIALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_ELEMENTS_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DOMAIN_TOPOLOGY_ELEMENTS_INITIALISE


  !
  !================================================================================================================================
  !

  !>Finalises the topology in the given domain. \todo pass in domain topology
  SUBROUTINE DOMAIN_TOPOLOGY_FINALISE(DOMAIN,ERR,ERROR,*)

   !Argument variables
    TYPE(DOMAIN_TYPE), POINTER :: DOMAIN !<A pointer to the domain to finalise the topology for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_TOPOLOGY_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(DOMAIN)) THEN
      CALL DOMAIN_TOPOLOGY_NODES_FINALISE(DOMAIN%TOPOLOGY,ERR,ERROR,*999)
      CALL DOMAIN_TOPOLOGY_DOFS_FINALISE(DOMAIN%TOPOLOGY,ERR,ERROR,*999)
      CALL DOMAIN_TOPOLOGY_ELEMENTS_FINALISE(DOMAIN%TOPOLOGY,ERR,ERROR,*999)
      CALL DOMAIN_TOPOLOGY_LINES_FINALISE(DOMAIN%TOPOLOGY,ERR,ERROR,*999)
      CALL DOMAIN_TOPOLOGY_FACES_FINALISE(DOMAIN%TOPOLOGY,ERR,ERROR,*999)
      DEALLOCATE(DOMAIN%TOPOLOGY)
    ELSE
      CALL FlagError("Domain is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_TOPOLOGY_FINALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_FINALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DOMAIN_TOPOLOGY_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the topology for a given domain. \todo finalise on error
  SUBROUTINE DOMAIN_TOPOLOGY_INITIALISE(DOMAIN,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_TYPE), POINTER :: DOMAIN !A pointer to the domain to initialise the topology for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_TOPOLOGY_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(DOMAIN)) THEN
      IF(ASSOCIATED(DOMAIN%TOPOLOGY)) THEN
        CALL FlagError("Domain already has topology associated",ERR,ERROR,*999)
      ELSE
        !Allocate domain topology
        ALLOCATE(DOMAIN%TOPOLOGY,STAT=ERR)
        IF(ERR/=0) CALL FlagError("Domain topology could not be allocated",ERR,ERROR,*999)
        DOMAIN%TOPOLOGY%DOMAIN=>DOMAIN
        NULLIFY(DOMAIN%TOPOLOGY%ELEMENTS)
        NULLIFY(DOMAIN%TOPOLOGY%NODES)
        NULLIFY(DOMAIN%TOPOLOGY%DOFS)
        NULLIFY(DOMAIN%TOPOLOGY%LINES)
        NULLIFY(DOMAIN%TOPOLOGY%FACES)
        !Initialise the topology components
        CALL DOMAIN_TOPOLOGY_ELEMENTS_INITIALISE(DOMAIN%TOPOLOGY,ERR,ERROR,*999)
        CALL DOMAIN_TOPOLOGY_NODES_INITIALISE(DOMAIN%TOPOLOGY,ERR,ERROR,*999)
        CALL DOMAIN_TOPOLOGY_DOFS_INITIALISE(DOMAIN%TOPOLOGY,ERR,ERROR,*999)
        CALL DOMAIN_TOPOLOGY_LINES_INITIALISE(DOMAIN%TOPOLOGY,ERR,ERROR,*999)
        CALL DOMAIN_TOPOLOGY_FACES_INITIALISE(DOMAIN%TOPOLOGY,ERR,ERROR,*999)
        !Initialise the domain topology from the domain mappings and the mesh it came from
        CALL DOMAIN_TOPOLOGY_INITIALISE_FROM_MESH(DOMAIN,ERR,ERROR,*999)
        !Calculate the topological information.
        CALL DOMAIN_TOPOLOGY_CALCULATE(DOMAIN%TOPOLOGY,ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Domain is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_TOPOLOGY_INITIALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DOMAIN_TOPOLOGY_INITIALISE

  !
  !================================================================================================================================
  !

  !>Get the basis for an element in the domain identified by its user number
  SUBROUTINE DomainTopology_ElementBasisGet(domainTopology,userElementNumber,basis,err,error,*)

    !Argument variables
    TYPE(DOMAIN_TOPOLOGY_TYPE), POINTER :: domainTopology !<A pointer to the domain topology to get the element basis for
    INTEGER(INTG), INTENT(IN) :: userElementNumber !<The element user number to get the basis for
    TYPE(BASIS_TYPE), POINTER, INTENT(OUT) :: basis !<On return, a pointer to the basis for the element.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    LOGICAL :: userElementExists,ghostElement
    INTEGER(INTG) :: localElementNumber
    TYPE(VARYING_STRING) :: localError

    ENTERS("DomainTopology_ElementBasisGet",err,error,*999)

    IF(.NOT.ASSOCIATED(domainTopology)) CALL FlagError("Domain topology is not associated.",err,error,*999)
    IF(ASSOCIATED(basis)) CALL FlagError("Basis is already associated.",err,error,*999)
    IF(.NOT.ASSOCIATED(domainTopology%elements)) CALL FlagError("Domain topology elements is not associated.",err,error,*999)
    IF(.NOT.ASSOCIATED(domainTopology%elements%elements)) &
      & CALL FlagError("Domain topology elements elements is not associated.",err,error,*999)
    IF(.NOT.ASSOCIATED(domainTopology%domain)) CALL FlagError("Domain topology domain is not associated.",err,error,*999)
    IF(.NOT.ASSOCIATED(domainTopology%domain%decomposition)) &
      & CALL FlagError("Domain topology domain decomposition is not associated.",err,error,*999)
    IF(.NOT.ASSOCIATED(domainTopology%domain%decomposition%topology)) &
      & CALL FlagError("Domain topology domain decomposition topology is not associated.",err,error,*999)

    CALL DecompositionTopology_ElementCheckExists(domainTopology%domain%decomposition%topology,userElementNumber, &
      & userElementExists,localElementNumber,ghostElement,err,error,*999)
    IF(.NOT.userElementExists) THEN
      CALL FlagError("The specified user element number of "// &
        & TRIM(NumberToVstring(userElementNumber,"*",err,error))// &
        & " does not exist in the domain decomposition.",err,error,*999)
    END IF

    basis=>domainTopology%elements%elements(localElementNumber)%basis
    IF(.NOT.ASSOCIATED(basis)) THEN
      localError="The basis for user element number "//TRIM(NumberToVString(userElementNumber,"*",err,error))// &
        & " is not associated."
      CALL FlagError(localError,err,error,*999)
    ENDIF

    EXITS("DomainTopology_ElementBasisGet")
    RETURN
999 ERRORSEXITS("DomainTopology_ElementBasisGet",err,error)
    RETURN 1

  END SUBROUTINE DomainTopology_ElementBasisGet

  !
  !================================================================================================================================
  !

  !>Finalises a line in the given domain topology and deallocates all memory.
  SUBROUTINE DOMAIN_TOPOLOGY_LINE_FINALISE(LINE,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_LINE_TYPE) :: LINE !<The domain line to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_TOPOLOGY_LINE_FINALISE",ERR,ERROR,*999)

    LINE%NUMBER=0
    NULLIFY(LINE%BASIS)
    IF(ALLOCATED(LINE%NODES_IN_LINE)) DEALLOCATE(LINE%NODES_IN_LINE)
    IF(ALLOCATED(LINE%DERIVATIVES_IN_LINE)) DEALLOCATE(LINE%DERIVATIVES_IN_LINE)

    EXITS("DOMAIN_TOPOLOGY_LINE_FINALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_LINE_FINALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DOMAIN_TOPOLOGY_LINE_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the line data structure for a domain topology line.
  SUBROUTINE DOMAIN_TOPOLOGY_LINE_INITIALISE(LINE,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_LINE_TYPE) :: LINE !<The domain line to initialise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_TOPOLOGY_LINE_INITIALISE",ERR,ERROR,*999)

    LINE%NUMBER=0
    NULLIFY(LINE%BASIS)
    LINE%BOUNDARY_LINE=.FALSE.

    EXITS("DOMAIN_TOPOLOGY_LINE_INITIALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_LINE_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DOMAIN_TOPOLOGY_LINE_INITIALISE

  !
  !================================================================================================================================
  !

  !>Finalises the lines in the given domain topology. \todo pass in domain lines
  SUBROUTINE DOMAIN_TOPOLOGY_LINES_FINALISE(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the domain topology to finalise the lines for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: nl

    ENTERS("DOMAIN_TOPOLOGY_LINES_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      IF(ASSOCIATED(TOPOLOGY%LINES)) THEN
        DO nl=1,TOPOLOGY%LINES%NUMBER_OF_LINES
          CALL DOMAIN_TOPOLOGY_LINE_FINALISE(TOPOLOGY%LINES%LINES(nl),ERR,ERROR,*999)
        ENDDO !nl
        IF(ALLOCATED(TOPOLOGY%LINES%LINES)) DEALLOCATE(TOPOLOGY%LINES%LINES)
        DEALLOCATE(TOPOLOGY%LINES)
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_TOPOLOGY_LINES_FINALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_LINES_FINALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DOMAIN_TOPOLOGY_LINES_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the line data structures for a domain topology. \todo finalise on error
  SUBROUTINE DOMAIN_TOPOLOGY_LINES_INITIALISE(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the domain topology to initialise the lines for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_TOPOLOGY_LINES_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      IF(ASSOCIATED(TOPOLOGY%LINES)) THEN
        CALL FlagError("Decomposition already has topology lines associated",ERR,ERROR,*999)
      ELSE
        ALLOCATE(TOPOLOGY%LINES,STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate topology lines",ERR,ERROR,*999)
        TOPOLOGY%LINES%NUMBER_OF_LINES=0
        TOPOLOGY%LINES%DOMAIN=>TOPOLOGY%DOMAIN
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_TOPOLOGY_LINES_INITIALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_LINES_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DOMAIN_TOPOLOGY_LINES_INITIALISE

  !
  !================================================================================================================================
  !
  !>Finalises a face in the given domain topology and deallocates all memory.
  SUBROUTINE DOMAIN_TOPOLOGY_FACE_FINALISE(FACE,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_FACE_TYPE) :: FACE !<The domain face to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_TOPOLOGY_FACE_FINALISE",ERR,ERROR,*999)

    FACE%NUMBER=0
    NULLIFY(FACE%BASIS)
    IF(ALLOCATED(FACE%NODES_IN_FACE)) DEALLOCATE(FACE%NODES_IN_FACE)
    IF(ALLOCATED(FACE%DERIVATIVES_IN_FACE)) DEALLOCATE(FACE%DERIVATIVES_IN_FACE)

    EXITS("DOMAIN_TOPOLOGY_FACE_FINALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_FACE_FINALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DOMAIN_TOPOLOGY_FACE_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the face data structure for a domain topology face.
  SUBROUTINE DOMAIN_TOPOLOGY_FACE_INITIALISE(FACE,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_FACE_TYPE) :: FACE !<The domain face to initialise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_TOPOLOGY_FACE_INITIALISE",ERR,ERROR,*999)

    FACE%NUMBER=0
    NULLIFY(FACE%BASIS)
    FACE%BOUNDARY_FACE=.FALSE.

    EXITS("DOMAIN_TOPOLOGY_FACE_INITIALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_FACE_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DOMAIN_TOPOLOGY_FACE_INITIALISE

  !
  !================================================================================================================================
  !

  !>Finalises the faces in the given domain topology. \todo pass in domain faces
  SUBROUTINE DOMAIN_TOPOLOGY_FACES_FINALISE(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the domain topology to finalise the faces for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: nf

    ENTERS("DOMAIN_TOPOLOGY_FACES_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      IF(ASSOCIATED(TOPOLOGY%FACES)) THEN
        DO nf=1,TOPOLOGY%FACES%NUMBER_OF_FACES
          CALL DOMAIN_TOPOLOGY_FACE_FINALISE(TOPOLOGY%FACES%FACES(nf),ERR,ERROR,*999)
        ENDDO !nf
        IF(ALLOCATED(TOPOLOGY%FACES%FACES)) DEALLOCATE(TOPOLOGY%FACES%FACES)
        DEALLOCATE(TOPOLOGY%FACES)
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_TOPOLOGY_FACES_FINALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_FACES_FINALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DOMAIN_TOPOLOGY_FACES_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the face data structures for a domain topology. \todo finalise on error
  SUBROUTINE DOMAIN_TOPOLOGY_FACES_INITIALISE(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the domain topology to initialise the faces for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_TOPOLOGY_FACES_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      IF(ASSOCIATED(TOPOLOGY%FACES)) THEN
        CALL FlagError("Decomposition already has topology faces associated",ERR,ERROR,*999)
      ELSE
        ALLOCATE(TOPOLOGY%FACES,STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate topology faces",ERR,ERROR,*999)
        TOPOLOGY%FACES%NUMBER_OF_FACES=0
        TOPOLOGY%FACES%DOMAIN=>TOPOLOGY%DOMAIN
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_TOPOLOGY_FACES_INITIALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_FACES_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DOMAIN_TOPOLOGY_FACES_INITIALISE

  !
  !================================================================================================================================
  !

  !>Checks that a user node number exists in a domain nodes topolgoy.
  SUBROUTINE DOMAIN_TOPOLOGY_NODE_CHECK_EXISTS(DOMAIN_TOPOLOGY,USER_NODE_NUMBER,NODE_EXISTS,DOMAIN_LOCAL_NODE_NUMBER, &
    & GHOST_NODE,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_TOPOLOGY_TYPE), POINTER :: DOMAIN_TOPOLOGY !<A pointer to the domain topology to check the node exists on
    INTEGER(INTG), INTENT(IN) :: USER_NODE_NUMBER !<The user node number to check if it exists
    LOGICAL, INTENT(OUT) :: NODE_EXISTS !<On exit, is .TRUE. if the node user number exists in the domain nodes topolgoy (even if it is a ghost node), .FALSE. if not
    INTEGER(INTG), INTENT(OUT) :: DOMAIN_LOCAL_NODE_NUMBER !<On exit, if the node exists the local number corresponding to the user node number. If the node does not exist then global number will be 0.
    LOGICAL, INTENT(OUT) :: GHOST_NODE !<On exit, is .TRUE. if the local node (if it exists) is a ghost node, .FALSE. if not.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(DOMAIN_NODES_TYPE), POINTER :: DOMAIN_NODES
    TYPE(TREE_NODE_TYPE), POINTER :: TREE_NODE

    ENTERS("DOMAIN_TOPOLOGY_NODE_CHECK_EXISTS",ERR,ERROR,*999)

    NODE_EXISTS=.FALSE.
    DOMAIN_LOCAL_NODE_NUMBER=0
    GHOST_NODE=.FALSE.
    IF(ASSOCIATED(DOMAIN_TOPOLOGY)) THEN
      DOMAIN_NODES=>DOMAIN_TOPOLOGY%NODES
      IF(ASSOCIATED(DOMAIN_NODES)) THEN
        NULLIFY(TREE_NODE)
        CALL TREE_SEARCH(DOMAIN_NODES%NODES_TREE,USER_NODE_NUMBER,TREE_NODE,ERR,ERROR,*999)
        IF(ASSOCIATED(TREE_NODE)) THEN
          CALL TREE_NODE_VALUE_GET(DOMAIN_NODES%NODES_TREE,TREE_NODE,DOMAIN_LOCAL_NODE_NUMBER,ERR,ERROR,*999)
          NODE_EXISTS=.TRUE.
          GHOST_NODE=DOMAIN_LOCAL_NODE_NUMBER>DOMAIN_NODES%NUMBER_OF_NODES
        ENDIF
      ELSE
        CALL FlagError("Domain topology nodes is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Domain topology is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_TOPOLOGY_NODE_CHECK_EXISTS")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_NODE_CHECK_EXISTS",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DOMAIN_TOPOLOGY_NODE_CHECK_EXISTS

  !
  !================================================================================================================================
  !

  !>Finalises the given domain topology node derivative and deallocates all memory.
  SUBROUTINE DOMAIN_TOPOLOGY_NODE_DERIVATIVE_FINALISE(NODE_DERIVATIVE,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_NODE_DERIVATIVE_TYPE) :: NODE_DERIVATIVE !<The domain node to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_TOPOLOGY_NODE_DERIVATIVE_FINALISE",ERR,ERROR,*999)

    IF(ALLOCATED(NODE_DERIVATIVE%userVersionNumbers)) DEALLOCATE(NODE_DERIVATIVE%userVersionNumbers)
    IF(ALLOCATED(NODE_DERIVATIVE%DOF_INDEX)) DEALLOCATE(NODE_DERIVATIVE%DOF_INDEX)

    EXITS("DOMAIN_TOPOLOGY_NODE_DERIVATIVE_FINALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_NODE_DERIVATIVE_FINALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DOMAIN_TOPOLOGY_NODE_DERIVATIVE_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the given mesh topology node.
  SUBROUTINE DOMAIN_TOPOLOGY_NODE_DERIVATIVE_INITIALISE(NODE_DERIVATIVE,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_NODE_DERIVATIVE_TYPE) :: NODE_DERIVATIVE !<The domain node to initialise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_TOPOLOGY_NODE_DERIVATIVE_INITIALISE",ERR,ERROR,*999)

    NODE_DERIVATIVE%numberOfVersions=0
    NODE_DERIVATIVE%GLOBAL_DERIVATIVE_INDEX=0
    NODE_DERIVATIVE%PARTIAL_DERIVATIVE_INDEX=0

    EXITS("DOMAIN_TOPOLOGY_NODE_DERIVATIVE_INITIALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_NODE_DERIVATIVE_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DOMAIN_TOPOLOGY_NODE_DERIVATIVE_INITIALISE

  !
  !================================================================================================================================
  !

  !>Finalises the given domain topology node and deallocates all memory.
  SUBROUTINE DOMAIN_TOPOLOGY_NODE_FINALISE(NODE,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_NODE_TYPE) :: NODE !<The domain node to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: derivative_idx

    ENTERS("DOMAIN_TOPOLOGY_NODE_FINALISE",ERR,ERROR,*999)

    IF(ALLOCATED(NODE%DERIVATIVES)) THEN
      DO derivative_idx=1,NODE%NUMBER_OF_DERIVATIVES
        CALL DOMAIN_TOPOLOGY_NODE_DERIVATIVE_FINALISE(NODE%DERIVATIVES(derivative_idx),ERR,ERROR,*999)
      ENDDO !derivative_idx
      DEALLOCATE(NODE%DERIVATIVES)
    ENDIF
    IF(ASSOCIATED(NODE%SURROUNDING_ELEMENTS)) DEALLOCATE(NODE%SURROUNDING_ELEMENTS)
    IF(ALLOCATED(NODE%NODE_LINES)) DEALLOCATE(NODE%NODE_LINES)

    EXITS("DOMAIN_TOPOLOGY_NODE_FINALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_NODE_FINALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DOMAIN_TOPOLOGY_NODE_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the given domain topology node.
  SUBROUTINE DOMAIN_TOPOLOGY_NODE_INITIALISE(NODE,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_NODE_TYPE) :: NODE !<The domain node to initialise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_TOPOLOGY_NODE_INITIALISE",ERR,ERROR,*999)

    NODE%LOCAL_NUMBER=0
    NODE%MESH_NUMBER=0
    NODE%GLOBAL_NUMBER=0
    NODE%USER_NUMBER=0
    NODE%NUMBER_OF_SURROUNDING_ELEMENTS=0
    NODE%NUMBER_OF_NODE_LINES=0
    NODE%BOUNDARY_NODE=.FALSE.

    EXITS("DOMAIN_TOPOLOGY_NODE_INITIALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_NODE_INITIALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DOMAIN_TOPOLOGY_NODE_INITIALISE

  !
  !================================================================================================================================
  !

  !>Finalises the nodees in the given domain topology. \todo pass in domain nodes
  SUBROUTINE DOMAIN_TOPOLOGY_NODES_FINALISE(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the domain topology to initialise the nodes for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: np

    ENTERS("DOMAIN_TOPOLOGY_NODES_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      IF(ASSOCIATED(TOPOLOGY%NODES)) THEN
        DO np=1,TOPOLOGY%NODES%TOTAL_NUMBER_OF_NODES
          CALL DOMAIN_TOPOLOGY_NODE_FINALISE(TOPOLOGY%NODES%NODES(np),ERR,ERROR,*999)
        ENDDO !np
        IF(ASSOCIATED(TOPOLOGY%NODES%NODES)) DEALLOCATE(TOPOLOGY%NODES%NODES)
        IF(ASSOCIATED(TOPOLOGY%NODES%NODES_TREE)) CALL TREE_DESTROY(TOPOLOGY%NODES%NODES_TREE,ERR,ERROR,*999)
        DEALLOCATE(TOPOLOGY%NODES)
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_TOPOLOGY_NODES_FINALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_NODES_FINALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE DOMAIN_TOPOLOGY_NODES_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the nodes data structures for a domain topology. \todo finalise on error
  SUBROUTINE DOMAIN_TOPOLOGY_NODES_INITIALISE(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the domain topology to initialise the nodes for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("DOMAIN_TOPOLOGY_NODES_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      IF(ASSOCIATED(TOPOLOGY%NODES)) THEN
        CALL FlagError("Decomposition already has topology nodes associated",ERR,ERROR,*999)
      ELSE
        ALLOCATE(TOPOLOGY%NODES,STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate topology nodes",ERR,ERROR,*999)
        TOPOLOGY%NODES%NUMBER_OF_NODES=0
        TOPOLOGY%NODES%TOTAL_NUMBER_OF_NODES=0
        TOPOLOGY%NODES%NUMBER_OF_GLOBAL_NODES=0
        TOPOLOGY%NODES%MAXIMUM_NUMBER_OF_DERIVATIVES=0
        TOPOLOGY%NODES%DOMAIN=>TOPOLOGY%DOMAIN
        NULLIFY(TOPOLOGY%NODES%NODES)
        NULLIFY(TOPOLOGY%NODES%NODES_TREE)
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("DOMAIN_TOPOLOGY_NODES_INITIALISE")
    RETURN
999 ERRORSEXITS("DOMAIN_TOPOLOGY_NODES_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DOMAIN_TOPOLOGY_NODES_INITIALISE

  !
  !================================================================================================================================
  !

  !>Calculates the element numbers surrounding a node for a domain.
  SUBROUTINE DomainTopology_NodesSurroundingElementsCalculate(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(DOMAIN_TOPOLOGY_TYPE), POINTER :: TOPOLOGY !<A pointer to the domain topology to calculate the elements surrounding the nodes for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: element_no,insert_position,ne,nn,np,surrounding_elem_no
    INTEGER(INTG), POINTER :: NEW_SURROUNDING_ELEMENTS(:)
    LOGICAL :: FOUND_ELEMENT
    TYPE(BASIS_TYPE), POINTER :: BASIS

    NULLIFY(NEW_SURROUNDING_ELEMENTS)

    ENTERS("DomainTopology_NodesSurroundingElementsCalculate",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      IF(ASSOCIATED(TOPOLOGY%ELEMENTS)) THEN
        IF(ASSOCIATED(TOPOLOGY%NODES)) THEN
          IF(ASSOCIATED(TOPOLOGY%NODES%NODES)) THEN
            DO np=1,TOPOLOGY%NODES%TOTAL_NUMBER_OF_NODES
              TOPOLOGY%NODES%NODES(np)%NUMBER_OF_SURROUNDING_ELEMENTS=0
              IF(ASSOCIATED(TOPOLOGY%NODES%NODES(np)%SURROUNDING_ELEMENTS)) &
                & DEALLOCATE(TOPOLOGY%NODES%NODES(np)%SURROUNDING_ELEMENTS)
            ENDDO !np
            DO ne=1,TOPOLOGY%ELEMENTS%TOTAL_NUMBER_OF_ELEMENTS
              BASIS=>TOPOLOGY%ELEMENTS%ELEMENTS(ne)%BASIS
              DO nn=1,BASIS%NUMBER_OF_NODES
                np=TOPOLOGY%ELEMENTS%ELEMENTS(ne)%ELEMENT_NODES(nn)
                FOUND_ELEMENT=.FALSE.
                element_no=1
                insert_position=1
                DO WHILE(element_no<=TOPOLOGY%NODES%NODES(np)%NUMBER_OF_SURROUNDING_ELEMENTS.AND..NOT.FOUND_ELEMENT)
                  surrounding_elem_no=TOPOLOGY%NODES%NODES(np)%SURROUNDING_ELEMENTS(element_no)
                  IF(surrounding_elem_no==ne) THEN
                    FOUND_ELEMENT=.TRUE.
                  ENDIF
                  element_no=element_no+1
                  IF(ne>=surrounding_elem_no) THEN
                    insert_position=element_no
                  ENDIF
                ENDDO
                IF(.NOT.FOUND_ELEMENT) THEN
                  !Insert element into surrounding elements
                  ALLOCATE(NEW_SURROUNDING_ELEMENTS(TOPOLOGY%NODES%NODES(np)%NUMBER_OF_SURROUNDING_ELEMENTS+1),STAT=ERR)
                  IF(ERR/=0) CALL FlagError("Could not allocate new surrounding elements",ERR,ERROR,*999)
                  IF(ASSOCIATED(TOPOLOGY%NODES%NODES(np)%SURROUNDING_ELEMENTS)) THEN
                    NEW_SURROUNDING_ELEMENTS(1:insert_position-1)=TOPOLOGY%NODES%NODES(np)% &
                      & SURROUNDING_ELEMENTS(1:insert_position-1)
                    NEW_SURROUNDING_ELEMENTS(insert_position)=ne
                    NEW_SURROUNDING_ELEMENTS(insert_position+1:TOPOLOGY%NODES%NODES(np)% &
                      & NUMBER_OF_SURROUNDING_ELEMENTS+1)=TOPOLOGY%NODES%NODES(np)%SURROUNDING_ELEMENTS(insert_position: &
                      & TOPOLOGY%NODES%NODES(np)%NUMBER_OF_SURROUNDING_ELEMENTS)
                    DEALLOCATE(TOPOLOGY%NODES%NODES(np)%SURROUNDING_ELEMENTS)
                  ELSE
                    NEW_SURROUNDING_ELEMENTS(1)=ne
                  ENDIF
                  TOPOLOGY%NODES%NODES(np)%SURROUNDING_ELEMENTS=>NEW_SURROUNDING_ELEMENTS
                  TOPOLOGY%NODES%NODES(np)%NUMBER_OF_SURROUNDING_ELEMENTS= &
                    & TOPOLOGY%NODES%NODES(np)%NUMBER_OF_SURROUNDING_ELEMENTS+1
                ENDIF
              ENDDO !nn
            ENDDO !ne
          ELSE
            CALL FlagError("Domain topology nodes nodes are not associated",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Domain topology nodes are not associated",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Domain topology elements is not associated",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Domain topology is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("DomainTopology_NodesSurroundingElementsCalculate")
    RETURN
999 IF(ASSOCIATED(NEW_SURROUNDING_ELEMENTS)) DEALLOCATE(NEW_SURROUNDING_ELEMENTS)
    ERRORS("DomainTopology_NodesSurroundingElementsCalculate",ERR,ERROR)
    EXITS("DomainTopology_NodesSurroundingElementsCalculate")
    RETURN 1
  END SUBROUTINE DomainTopology_NodesSurroundingElementsCalculate

  !
  !================================================================================================================================
  !

  !>Finialises the mesh adjacent elements information and deallocates all memory
  SUBROUTINE MESH_ADJACENT_ELEMENT_FINALISE(MESH_ADJACENT_ELEMENT,ERR,ERROR,*)

    !Argument variables
    TYPE(MESH_ADJACENT_ELEMENT_TYPE) :: MESH_ADJACENT_ELEMENT !<The mesh adjacent element to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("MESH_ADJACENT_ELEMENT_FINALISE",ERR,ERROR,*999)

    MESH_ADJACENT_ELEMENT%NUMBER_OF_ADJACENT_ELEMENTS=0
    IF(ALLOCATED(MESH_ADJACENT_ELEMENT%ADJACENT_ELEMENTS)) DEALLOCATE(MESH_ADJACENT_ELEMENT%ADJACENT_ELEMENTS)

    EXITS("MESH_ADJACENT_ELEMENT_FINALISE")
    RETURN
999 ERRORSEXITS("MESH_ADJACENT_ELEMENT_FINALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE MESH_ADJACENT_ELEMENT_FINALISE

  !
  !================================================================================================================================
  !
  !>Initalises the mesh adjacent elements information.
  SUBROUTINE MESH_ADJACENT_ELEMENT_INITIALISE(MESH_ADJACENT_ELEMENT,ERR,ERROR,*)

    !Argument variables
    TYPE(MESH_ADJACENT_ELEMENT_TYPE) :: MESH_ADJACENT_ELEMENT !<The mesh adjacent element to initialise.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("MESH_ADJACENT_ELEMENT_INITIALISE",ERR,ERROR,*999)

    MESH_ADJACENT_ELEMENT%NUMBER_OF_ADJACENT_ELEMENTS=0

    EXITS("MESH_ADJACENT_ELEMENT_INITIALISE")
    RETURN
999 ERRORSEXITS("MESH_ADJACENT_ELEMENT_INITIALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE MESH_ADJACENT_ELEMENT_INITIALISE

  !
  !================================================================================================================================
  !

  !>Finishes the process of creating a mesh. \see OPENCMISS::Iron::cmfe_MeshCreateFinish
  SUBROUTINE MESH_CREATE_FINISH(MESH,ERR,ERROR,*)

    !Argument variables
    TYPE(MESH_TYPE), POINTER :: MESH !<A pointer to the mesh to finish creating
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: component_idx
    LOGICAL :: FINISHED
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("MESH_CREATE_FINISH",ERR,ERROR,*999)

    IF(ASSOCIATED(MESH)) THEN
      IF(ASSOCIATED(MESH%TOPOLOGY)) THEN
        !Check that the mesh component elements have been finished
        FINISHED=.TRUE.
        DO component_idx=1,MESH%NUMBER_OF_COMPONENTS
          IF(ASSOCIATED(MESH%TOPOLOGY(component_idx)%PTR%ELEMENTS)) THEN
            IF(.NOT.MESH%TOPOLOGY(component_idx)%PTR%ELEMENTS%ELEMENTS_FINISHED) THEN
              LOCAL_ERROR="The elements for mesh component "//TRIM(NUMBER_TO_VSTRING(component_idx,"*",ERR,ERROR))// &
                & " have not been finished"
              FINISHED=.FALSE.
              EXIT
            ENDIF
          ELSE
            LOCAL_ERROR="The elements for mesh topology component "//TRIM(NUMBER_TO_VSTRING(component_idx,"*",ERR,ERROR))// &
              & " are not associated"
            FINISHED=.FALSE.
            EXIT
          ENDIF
        ENDDO !component_idx
        IF(.NOT.FINISHED) CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
        MESH%MESH_FINISHED=.TRUE.
        !Calulcate the mesh topology
        DO component_idx=1,MESH%NUMBER_OF_COMPONENTS
          CALL MeshTopology_Calculate(MESH%TOPOLOGY(component_idx)%PTR,ERR,ERROR,*999)
        ENDDO !component_idx
      ELSE
        CALL FlagError("Mesh topology is not associated",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Mesh is not associated",ERR,ERROR,*999)
    ENDIF

    IF(DIAGNOSTICS1) THEN
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  Mesh user number       = ",MESH%USER_NUMBER,ERR,ERROR,*999)
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Global number        = ",MESH%GLOBAL_NUMBER,ERR,ERROR,*999)
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Number of dimensions = ",MESH%NUMBER_OF_DIMENSIONS,ERR,ERROR,*999)
    ENDIF

    EXITS("MESH_CREATE_FINISH")
    RETURN
999 ERRORSEXITS("MESH_CREATE_FINISH",ERR,ERROR)
    RETURN 1

  END SUBROUTINE MESH_CREATE_FINISH

  !
  !================================================================================================================================
  !

  !>Starts the process of creating a mesh
  SUBROUTINE MESH_CREATE_START_GENERIC(MESHES,USER_NUMBER,NUMBER_OF_DIMENSIONS,MESH,ERR,ERROR,*)

    !Argument variables
    TYPE(MESHES_TYPE), POINTER :: MESHES !<The pointer to the meshes
    INTEGER(INTG), INTENT(IN) :: USER_NUMBER !<The user number of the mesh to create
    INTEGER(INTG), INTENT(IN) :: NUMBER_OF_DIMENSIONS !<The number of dimensions in the mesh.
    TYPE(MESH_TYPE), POINTER :: MESH !<On return, a pointer to the mesh. Must not be associated on entry
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR,mesh_idx
    TYPE(MESH_TYPE), POINTER :: NEW_MESH
    TYPE(MESH_PTR_TYPE), POINTER :: NEW_MESHES(:)
    TYPE(VARYING_STRING) :: DUMMY_ERROR

    NULLIFY(NEW_MESH)
    NULLIFY(NEW_MESHES)

    ENTERS("MESH_CREATE_START_GENERIC",ERR,ERROR,*997)

    IF(ASSOCIATED(MESHES)) THEN
      IF(ASSOCIATED(MESH)) THEN
        CALL FlagError("Mesh is already associated.",ERR,ERROR,*997)
      ELSE
        CALL MESH_INITIALISE(NEW_MESH,ERR,ERROR,*999)
        !Set default mesh values
        NEW_MESH%USER_NUMBER=USER_NUMBER
        NEW_MESH%GLOBAL_NUMBER=MESHES%NUMBER_OF_MESHES+1
        NEW_MESH%MESHES=>MESHES
        NEW_MESH%NUMBER_OF_DIMENSIONS=NUMBER_OF_DIMENSIONS
        NEW_MESH%NUMBER_OF_COMPONENTS=1
        NEW_MESH%SURROUNDING_ELEMENTS_CALCULATE=.true. !default true
        !Initialise mesh topology and decompositions
        CALL MeshTopology_Initialise(NEW_MESH,ERR,ERROR,*999)
        CALL DECOMPOSITIONS_INITIALISE(NEW_MESH,ERR,ERROR,*999)
        !Add new mesh into list of meshes
        ALLOCATE(NEW_MESHES(MESHES%NUMBER_OF_MESHES+1),STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate new meshes",ERR,ERROR,*999)
        DO mesh_idx=1,MESHES%NUMBER_OF_MESHES
          NEW_MESHES(mesh_idx)%PTR=>MESHES%MESHES(mesh_idx)%PTR
        ENDDO !mesh_idx
        NEW_MESHES(MESHES%NUMBER_OF_MESHES+1)%PTR=>NEW_MESH
        IF(ASSOCIATED(MESHES%MESHES)) DEALLOCATE(MESHES%MESHES)
        MESHES%MESHES=>NEW_MESHES
        MESHES%NUMBER_OF_MESHES=MESHES%NUMBER_OF_MESHES+1
        MESH=>NEW_MESH
      ENDIF
    ELSE
      CALL FlagError("Meshes is not associated.",ERR,ERROR,*997)
    ENDIF

    EXITS("MESH_CREATE_START_GENERIC")
    RETURN
999 CALL MESH_FINALISE(NEW_MESH,DUMMY_ERR,DUMMY_ERROR,*998)
998 IF(ASSOCIATED(NEW_MESHES)) DEALLOCATE(NEW_MESHES)
    NULLIFY(MESH)
997 ERRORSEXITS("MESH_CREATE_START_GENERIC",ERR,ERROR)
    RETURN 1

  END SUBROUTINE MESH_CREATE_START_GENERIC

  !
  !================================================================================================================================
  !

  !>Starts the process of creating a mesh defined by a user number with the specified NUMBER_OF_DIMENSIONS in an interface. \see OPENCMISS::Iron::cmfe_MeshCreateStart
  !>Default values set for the MESH's attributes are:
  !>- NUMBER_OF_COMPONENTS: 1
  SUBROUTINE MESH_CREATE_START_INTERFACE(USER_NUMBER,INTERFACE,NUMBER_OF_DIMENSIONS,MESH,ERR,ERROR,*)

    !Argument variables
    INTEGER(INTG), INTENT(IN) :: USER_NUMBER !<The user number of the mesh to create
    TYPE(INTERFACE_TYPE), POINTER :: INTERFACE !<A pointer to the interface to create the mesh on
    INTEGER(INTG), INTENT(IN) :: NUMBER_OF_DIMENSIONS !<The number of dimensions in the mesh.
    TYPE(MESH_TYPE), POINTER :: MESH !<On exit, a pointer to the created mesh. Must not be associated on entry.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(REGION_TYPE), POINTER :: PARENT_REGION
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("MESH_CREATE_START_INTERFACE",ERR,ERROR,*999)

    IF(ASSOCIATED(INTERFACE)) THEN
      IF(ASSOCIATED(MESH)) THEN
        CALL FlagError("Mesh is already associated.",ERR,ERROR,*999)
      ELSE
        NULLIFY(MESH)
        IF(ASSOCIATED(INTERFACE%MESHES)) THEN
          CALL Mesh_UserNumberFindGeneric(USER_NUMBER,INTERFACE%MESHES,MESH,ERR,ERROR,*999)
          IF(ASSOCIATED(MESH)) THEN
            LOCAL_ERROR="Mesh number "//TRIM(NUMBER_TO_VSTRING(USER_NUMBER,"*",ERR,ERROR))// &
              & " has already been created on interface number "// &
              & TRIM(NUMBER_TO_VSTRING(INTERFACE%USER_NUMBER,"*",ERR,ERROR))//"."
            CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
          ELSE
            IF(ASSOCIATED(INTERFACE%INTERFACES)) THEN
              PARENT_REGION=>INTERFACE%INTERFACES%PARENT_REGION
              IF(ASSOCIATED(PARENT_REGION)) THEN
                IF(ASSOCIATED(PARENT_REGION%COORDINATE_SYSTEM)) THEN
                  IF(NUMBER_OF_DIMENSIONS>0) THEN
                    IF(NUMBER_OF_DIMENSIONS<=PARENT_REGION%COORDINATE_SYSTEM%NUMBER_OF_DIMENSIONS) THEN
                      CALL MESH_CREATE_START_GENERIC(INTERFACE%MESHES,USER_NUMBER,NUMBER_OF_DIMENSIONS,MESH,ERR,ERROR,*999)
                      MESH%INTERFACE=>INTERFACE
                    ELSE
                      LOCAL_ERROR="Number of mesh dimensions ("//TRIM(NUMBER_TO_VSTRING(NUMBER_OF_DIMENSIONS,"*",ERR,ERROR))// &
                        & ") must be <= number of parent region dimensions ("// &
                        & TRIM(NUMBER_TO_VSTRING(PARENT_REGION%COORDINATE_SYSTEM%NUMBER_OF_DIMENSIONS,"*",ERR,ERROR))//")."
                      CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                    ENDIF
                  ELSE
                    CALL FlagError("Number of mesh dimensions must be > 0.",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FlagError("Parent region coordinate system is not associated.",ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FlagError("Interfaces parent region is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FlagError("Interface interfaces is not associated.",ERR,ERROR,*999)
            ENDIF
          ENDIF
        ELSE
          LOCAL_ERROR="The meshes on interface number "//TRIM(NUMBER_TO_VSTRING(INTERFACE%USER_NUMBER,"*",ERR,ERROR))// &
            & " are not associated."
          CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Interface is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("MESH_CREATE_START_INTERFACE")
    RETURN
999 ERRORSEXITS("MESH_CREATE_START_INTERFACE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE MESH_CREATE_START_INTERFACE

  !
  !================================================================================================================================
  !

  !>Starts the process of creating a mesh defined by a user number with the specified NUMBER_OF_DIMENSIONS in the region identified by REGION. \see OPENCMISS::Iron::cmfe_MeshCreateStart
  !>Default values set for the MESH's attributes are:
  !>- NUMBER_OF_COMPONENTS: 1
  SUBROUTINE MESH_CREATE_START_REGION(USER_NUMBER,REGION,NUMBER_OF_DIMENSIONS,MESH,ERR,ERROR,*)

    !Argument variables
    INTEGER(INTG), INTENT(IN) :: USER_NUMBER !<The user number of the mesh to create
    TYPE(REGION_TYPE), POINTER :: REGION !<A pointer to the region to create the mesh on
    INTEGER(INTG), INTENT(IN) :: NUMBER_OF_DIMENSIONS !<The number of dimensions in the mesh.
    TYPE(MESH_TYPE), POINTER :: MESH !<On exit, a pointer to the created mesh. Must not be associated on entry.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("MESH_CREATE_START_REGION",ERR,ERROR,*999)

    IF(ASSOCIATED(REGION)) THEN
      IF(ASSOCIATED(MESH)) THEN
        CALL FlagError("Mesh is already associated.",ERR,ERROR,*999)
      ELSE
        NULLIFY(MESH)
        IF(ASSOCIATED(REGION%MESHES)) THEN
          CALL Mesh_UserNumberFindGeneric(USER_NUMBER,REGION%MESHES,MESH,ERR,ERROR,*999)
          IF(ASSOCIATED(MESH)) THEN
            LOCAL_ERROR="Mesh number "//TRIM(NUMBER_TO_VSTRING(USER_NUMBER,"*",ERR,ERROR))// &
              & " has already been created on region number "//TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))//"."
            CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
          ELSE
            IF(ASSOCIATED(REGION%COORDINATE_SYSTEM)) THEN
              IF(NUMBER_OF_DIMENSIONS>0) THEN
                IF(NUMBER_OF_DIMENSIONS<=REGION%COORDINATE_SYSTEM%NUMBER_OF_DIMENSIONS) THEN
                  CALL MESH_CREATE_START_GENERIC(REGION%MESHES,USER_NUMBER,NUMBER_OF_DIMENSIONS,MESH,ERR,ERROR,*999)
                  MESH%REGION=>REGION
                ELSE
                  LOCAL_ERROR="Number of mesh dimensions ("//TRIM(NUMBER_TO_VSTRING(NUMBER_OF_DIMENSIONS,"*",ERR,ERROR))// &
                    & ") must be <= number of region dimensions ("// &
                    & TRIM(NUMBER_TO_VSTRING(REGION%COORDINATE_SYSTEM%NUMBER_OF_DIMENSIONS,"*",ERR,ERROR))//")."
                  CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FlagError("Number of mesh dimensions must be > 0.",ERR,ERROR,*999)
              ENDIF
            ELSE
              LOCAL_ERROR="The coordinate system on region number "//TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))// &
                & " are not associated."
              CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
            ENDIF
          ENDIF
        ELSE
          LOCAL_ERROR="The meshes on region number "//TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))// &
            & " are not associated."
          CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Region is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("MESH_CREATE_START_REGION")
    RETURN
999 ERRORSEXITS("MESH_CREATE_START_REGION",ERR,ERROR)
    RETURN 1

  END SUBROUTINE MESH_CREATE_START_REGION

  !
  !================================================================================================================================
  !

  !>Destroys the mesh identified by a user number on the given region and deallocates all memory. \see OPENCMISS::Iron::cmfe_MeshDestroy
  SUBROUTINE MESH_DESTROY_NUMBER(USER_NUMBER,REGION,ERR,ERROR,*)

    !Argument variables
    INTEGER(INTG), INTENT(IN) :: USER_NUMBER !<The user number of the mesh to destroy
    TYPE(REGION_TYPE), POINTER :: REGION !<A pointer to the region containing the mesh
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: mesh_idx,mesh_position
    LOGICAL :: FOUND
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    TYPE(MESH_TYPE), POINTER :: MESH
    TYPE(MESH_PTR_TYPE), POINTER :: NEW_MESHES(:)

    NULLIFY(NEW_MESHES)

    ENTERS("MESH_DESTROY_NUMBER",ERR,ERROR,*999)

    IF(ASSOCIATED(REGION)) THEN
      IF(ASSOCIATED(REGION%MESHES)) THEN

!!TODO: have a mesh_destory_ptr and mesh_destroy_number

        !Find the problem identified by the user number
        FOUND=.FALSE.
        mesh_position=0
        DO WHILE(mesh_position<REGION%MESHES%NUMBER_OF_MESHES.AND..NOT.FOUND)
          mesh_position=mesh_position+1
          IF(REGION%MESHES%MESHES(mesh_position)%PTR%USER_NUMBER==USER_NUMBER) FOUND=.TRUE.
        ENDDO

        IF(FOUND) THEN

          MESH=>REGION%MESHES%MESHES(mesh_position)%PTR

          CALL MESH_FINALISE(MESH,ERR,ERROR,*999)

          !Remove the mesh from the list of meshes
          IF(REGION%MESHES%NUMBER_OF_MESHES>1) THEN
            ALLOCATE(NEW_MESHES(REGION%MESHES%NUMBER_OF_MESHES-1),STAT=ERR)
            IF(ERR/=0) CALL FlagError("Could not allocate new meshes",ERR,ERROR,*999)
            DO mesh_idx=1,REGION%MESHES%NUMBER_OF_MESHES
              IF(mesh_idx<mesh_position) THEN
                NEW_MESHES(mesh_idx)%PTR=>REGION%MESHES%MESHES(mesh_idx)%PTR
              ELSE IF(mesh_idx>mesh_position) THEN
                REGION%MESHES%MESHES(mesh_idx)%PTR%GLOBAL_NUMBER=REGION%MESHES%MESHES(mesh_idx)%PTR%GLOBAL_NUMBER-1
                NEW_MESHES(mesh_idx-1)%PTR=>REGION%MESHES%MESHES(mesh_idx)%PTR
              ENDIF
            ENDDO !mesh_idx
            DEALLOCATE(REGION%MESHES%MESHES)
            REGION%MESHES%MESHES=>NEW_MESHES
            REGION%MESHES%NUMBER_OF_MESHES=REGION%MESHES%NUMBER_OF_MESHES-1
          ELSE
            DEALLOCATE(REGION%MESHES%MESHES)
            REGION%MESHES%NUMBER_OF_MESHES=0
          ENDIF

        ELSE
          LOCAL_ERROR="Mesh number "//TRIM(NUMBER_TO_VSTRING(USER_NUMBER,"*",ERR,ERROR))// &
            & " has not been created on region number "//TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))
          CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
        ENDIF
      ELSE
        LOCAL_ERROR="The meshes on region number "//TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))// &
          & " are not associated"
        CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Region is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("MESH_DESTROY_NUMBER")
    RETURN
999 IF(ASSOCIATED(NEW_MESHES)) DEALLOCATE(NEW_MESHES)
    ERRORSEXITS("MESH_DESTROY_NUMBER",ERR,ERROR)
    RETURN 1
  END SUBROUTINE MESH_DESTROY_NUMBER

  !
  !================================================================================================================================
  !

  !>Destroys the mesh and deallocates all memory. \see OPENCMISS::Iron::cmfe_MeshDestroy
  SUBROUTINE MESH_DESTROY(MESH,ERR,ERROR,*)

    !Argument variables
    TYPE(MESH_TYPE), POINTER :: MESH !<A pointer to the mesh to destroy.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: mesh_idx,mesh_position
    TYPE(MESHES_TYPE), POINTER :: MESHES
    TYPE(MESH_PTR_TYPE), POINTER :: NEW_MESHES(:)

    NULLIFY(NEW_MESHES)

    ENTERS("MESH_DESTROY",ERR,ERROR,*999)

    IF(ASSOCIATED(MESH)) THEN
      MESHES=>MESH%MESHES
      IF(ASSOCIATED(MESHES)) THEN
        mesh_position=MESH%GLOBAL_NUMBER

        CALL MESH_FINALISE(MESH,ERR,ERROR,*999)

        !Remove the mesh from the list of meshes
        IF(MESHES%NUMBER_OF_MESHES>1) THEN
          ALLOCATE(NEW_MESHES(MESHES%NUMBER_OF_MESHES-1),STAT=ERR)
          IF(ERR/=0) CALL FlagError("Could not allocate new meshes.",ERR,ERROR,*999)
          DO mesh_idx=1,MESHES%NUMBER_OF_MESHES
            IF(mesh_idx<mesh_position) THEN
              NEW_MESHES(mesh_idx)%PTR=>MESHES%MESHES(mesh_idx)%PTR
            ELSE IF(mesh_idx>mesh_position) THEN
              MESHES%MESHES(mesh_idx)%PTR%GLOBAL_NUMBER=MESHES%MESHES(mesh_idx)%PTR%GLOBAL_NUMBER-1
              NEW_MESHES(mesh_idx-1)%PTR=>MESHES%MESHES(mesh_idx)%PTR
            ENDIF
          ENDDO !mesh_idx
          DEALLOCATE(MESHES%MESHES)
          MESHES%MESHES=>NEW_MESHES
          MESHES%NUMBER_OF_MESHES=MESHES%NUMBER_OF_MESHES-1
        ELSE
          DEALLOCATE(MESHES%MESHES)
          MESHES%NUMBER_OF_MESHES=0
        ENDIF
      ELSE
        CALL FlagError("The mesh meshes is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Mesh is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("MESH_DESTROY")
    RETURN
999 IF(ASSOCIATED(NEW_MESHES)) DEALLOCATE(NEW_MESHES)
    ERRORSEXITS("MESH_DESTROY",ERR,ERROR)
    RETURN 1
  END SUBROUTINE MESH_DESTROY

  !
  !================================================================================================================================
  !

  !>Finalises a mesh and deallocates all memory.
  SUBROUTINE MESH_FINALISE(MESH,ERR,ERROR,*)

    !Argument variables
    TYPE(MESH_TYPE), POINTER :: MESH !<A pointer to the mesh to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("MESH_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(MESH)) THEN
      CALL MeshTopology_Finalise(MESH,ERR,ERROR,*999)
      CALL DECOMPOSITIONS_FINALISE(MESH,ERR,ERROR,*999)
!      IF(ASSOCIATED(MESH%INTF)) CALL INTERFACE_MESH_FINALISE(MESH,ERR,ERROR,*999)  ! <<??>>
      DEALLOCATE(MESH)
    ENDIF

    EXITS("MESH_FINALISE")
    RETURN
999 ERRORSEXITS("MESH_FINALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE MESH_FINALISE

  !
  !================================================================================================================================
  !

  !>Returns a region nodes pointer corresponding to the mesh global nodes accounting for interfaces.
  SUBROUTINE MeshGlobalNodesGet(mesh,nodes,err,error,*)

    !Argument variables
    TYPE(MESH_TYPE), POINTER :: mesh !<A pointer to the mesh to get the global nodes for
    TYPE(NODES_TYPE), POINTER :: nodes !<On return, the nodes pointer corresponding to the global nodes for the mesh. Must not be associated on entry.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    TYPE(INTERFACE_TYPE), POINTER :: interface
    TYPE(REGION_TYPE), POINTER :: region
    TYPE(VARYING_STRING) :: localError

    ENTERS("MeshGlobalNodesGet",err,error,*999)

    IF(ASSOCIATED(mesh)) THEN
      IF(ASSOCIATED(nodes)) THEN
        CALL FlagError("Nodes is already associated.",err,error,*999)
      ELSE
        NULLIFY(nodes)
        region=>mesh%region
        IF(ASSOCIATED(region)) THEN
          nodes=>region%nodes
        ELSE
          INTERFACE=>mesh%INTERFACE
          IF(ASSOCIATED(interface)) THEN
            nodes=>interface%nodes
          ELSE
            localError="Mesh number "//TRIM(NumberToVString(mesh%USER_NUMBER,"*",err,error))// &
              & " does not have an associated region or interface."
            CALL FlagError(localError,err,error,*999)
          ENDIF
        ENDIF
        IF(.NOT.ASSOCIATED(nodes)) THEN
          IF(ASSOCIATED(region)) THEN
            localError="Mesh number "//TRIM(NumberToVString(mesh%USER_NUMBER,"*",err,error))// &
              & " does not have any nodes associated with the mesh region."
          ELSE
            localError="Mesh number "//TRIM(NumberToVString(mesh%USER_NUMBER,"*",err,error))// &
              & " does not have any nodes associated with the mesh interface."
          ENDIF
          CALL FlagError(localError,err,error,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Mesh is not associated.",err,error,*999)
    ENDIF

    EXITS("MeshGlobalNodesGet")
    RETURN
999 ERRORSEXITS("MeshGlobalNodesGet",err,error)
    RETURN 1

  END SUBROUTINE MeshGlobalNodesGet

  !
  !================================================================================================================================
  !

  !>Initialises a mesh.
  SUBROUTINE MESH_INITIALISE(MESH,ERR,ERROR,*)

    !Argument variables
    TYPE(MESH_TYPE), POINTER :: MESH !<A pointer to the mesh to initialise. Must not be associated on entry.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("MESH_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(MESH)) THEN
      CALL FlagError("Mesh is already associated.",ERR,ERROR,*999)
    ELSE
      ALLOCATE(MESH,STAT=ERR)
      IF(ERR/=0) CALL FlagError("Could not allocate new mesh.",ERR,ERROR,*999)
      MESH%USER_NUMBER=0
      MESH%GLOBAL_NUMBER=0
      MESH%MESH_FINISHED=.FALSE.
      NULLIFY(MESH%MESHES)
      NULLIFY(MESH%REGION)
      NULLIFY(MESH%INTERFACE)
      NULLIFY(MESH%GENERATED_MESH)
      MESH%NUMBER_OF_DIMENSIONS=0
      MESH%NUMBER_OF_COMPONENTS=0
      MESH%MESH_EMBEDDED=.FALSE.
      NULLIFY(MESH%EMBEDDING_MESH)
      MESH%NUMBER_OF_EMBEDDED_MESHES=0
      NULLIFY(MESH%EMBEDDED_MESHES)
      MESH%NUMBER_OF_ELEMENTS=0
      NULLIFY(MESH%TOPOLOGY)
      NULLIFY(MESH%DECOMPOSITIONS)
    ENDIF

    EXITS("MESH_INITIALISE")
    RETURN
999 ERRORSEXITS("MESH_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE MESH_INITIALISE

  !
  !================================================================================================================================
  !

  !>Gets the number of mesh components for a mesh identified by a pointer. \see OPENCMISS::Iron::cmfe_MeshNumberOfComponentsGet
  SUBROUTINE MESH_NUMBER_OF_COMPONENTS_GET(MESH,NUMBER_OF_COMPONENTS,ERR,ERROR,*)

    !Argument variables
    TYPE(MESH_TYPE), POINTER :: MESH !<A pointer to the mesh to get the number of components for
    INTEGER(INTG), INTENT(OUT) :: NUMBER_OF_COMPONENTS !<On return, the number of components in the specified mesh.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("MESH_NUMBER_OF_COMPONENTS_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(MESH)) THEN
      IF(MESH%MESH_FINISHED) THEN
        NUMBER_OF_COMPONENTS=MESH%NUMBER_OF_COMPONENTS
      ELSE
        CALL FlagError("Mesh has not finished",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Mesh is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("MESH_NUMBER_OF_COMPONENTS_GET")
    RETURN
999 ERRORSEXITS("MESH_NUMBER_OF_COMPONENTS_GET",ERR,ERROR)
    RETURN
  END SUBROUTINE MESH_NUMBER_OF_COMPONENTS_GET

  !
  !================================================================================================================================
  !

  !>Changes/sets the number of mesh components for a mesh. \see OPENCMISS::Iron::cmfe_MeshNumberOfComponentsSet
  SUBROUTINE MESH_NUMBER_OF_COMPONENTS_SET(MESH,NUMBER_OF_COMPONENTS,ERR,ERROR,*)

    !Argument variables
    TYPE(MESH_TYPE), POINTER :: MESH !<A pointer to the mesh to set the number of components for
    INTEGER(INTG), INTENT(IN) :: NUMBER_OF_COMPONENTS !<The number of components to set.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: component_idx
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    TYPE(MeshComponentTopologyPtrType), POINTER :: NEW_TOPOLOGY(:)

    NULLIFY(NEW_TOPOLOGY)

    ENTERS("MESH_NUMBER_OF_COMPONENTS_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(MESH)) THEN
      IF(NUMBER_OF_COMPONENTS>0) THEN
        IF(MESH%MESH_FINISHED) THEN
          CALL FlagError("Mesh has been finished",ERR,ERROR,*999)
        ELSE
          IF(NUMBER_OF_COMPONENTS/=MESH%NUMBER_OF_COMPONENTS) THEN
            ALLOCATE(NEW_TOPOLOGY(NUMBER_OF_COMPONENTS),STAT=ERR)
            IF(ERR/=0) CALL FlagError("Could not allocate new topology",ERR,ERROR,*999)
            IF(NUMBER_OF_COMPONENTS<MESH%NUMBER_OF_COMPONENTS) THEN
              DO component_idx=1,NUMBER_OF_COMPONENTS
                NEW_TOPOLOGY(component_idx)%PTR=>MESH%TOPOLOGY(component_idx)%PTR
              ENDDO !component_idx
            ELSE !NUMBER_OF_COMPONENTS>MESH%NUMBER_OF_COMPONENTS
              DO component_idx=1,MESH%NUMBER_OF_COMPONENTS
                NEW_TOPOLOGY(component_idx)%PTR=>MESH%TOPOLOGY(component_idx)%PTR
              ENDDO !component_idx
!!TODO \todo sort out mesh_topology initialise/finalise so that they allocate and deal with this below then call that routine
              DO component_idx=MESH%NUMBER_OF_COMPONENTS+1,NUMBER_OF_COMPONENTS
                ALLOCATE(NEW_TOPOLOGY(component_idx)%PTR,STAT=ERR)
                IF(ERR/=0) CALL FlagError("Could not allocate new topology component",ERR,ERROR,*999)
                NEW_TOPOLOGY(component_idx)%PTR%mesh=>mesh
                NEW_TOPOLOGY(component_idx)%PTR%meshComponentNumber=component_idx
                NULLIFY(NEW_TOPOLOGY(component_idx)%PTR%elements)
                NULLIFY(NEW_TOPOLOGY(component_idx)%PTR%nodes)
                NULLIFY(NEW_TOPOLOGY(component_idx)%PTR%dofs)
                NULLIFY(NEW_TOPOLOGY(component_idx)%PTR%dataPoints)
                !Initialise the topology components
                CALL MESH_TOPOLOGY_ELEMENTS_INITIALISE(NEW_TOPOLOGY(component_idx)%PTR,ERR,ERROR,*999)
                CALL MeshTopology_NodesInitialise(NEW_TOPOLOGY(component_idx)%PTR,ERR,ERROR,*999)
                CALL MeshTopology_DofsInitialise(NEW_TOPOLOGY(component_idx)%PTR,ERR,ERROR,*999)
                CALL MESH_TOPOLOGY_DATA_POINTS_INITIALISE(NEW_TOPOLOGY(component_idx)%PTR,ERR,ERROR,*999)
              ENDDO !component_idx
            ENDIF
            IF(ASSOCIATED(MESH%TOPOLOGY)) DEALLOCATE(MESH%TOPOLOGY)
            MESH%TOPOLOGY=>NEW_TOPOLOGY
            MESH%NUMBER_OF_COMPONENTS=NUMBER_OF_COMPONENTS
          ENDIF
        ENDIF
      ELSE
        LOCAL_ERROR="The specified number of mesh components ("//TRIM(NUMBER_TO_VSTRING(NUMBER_OF_COMPONENTS,"*",ERR,ERROR))// &
          & ") is illegal. You must have >0 mesh components"
        CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Mesh is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("MESH_NUMBER_OF_COMPONENTS_SET")
    RETURN
!!TODO: tidy up memory deallocation on error
999 ERRORSEXITS("MESH_NUMBER_OF_COMPONENTS_SET",ERR,ERROR)
    RETURN 1

  END SUBROUTINE MESH_NUMBER_OF_COMPONENTS_SET

  !
  !================================================================================================================================
  !

  !>Gets the number of elements for a mesh identified by a pointer. \see OPENCMISS::Iron::cmfe_MeshNumberOfElementsGet
  SUBROUTINE MESH_NUMBER_OF_ELEMENTS_GET(MESH,NUMBER_OF_ELEMENTS,ERR,ERROR,*)

    !Argument variables
    TYPE(MESH_TYPE), POINTER :: MESH !<A pointer to the mesh to get the number of elements for
    INTEGER(INTG), INTENT(OUT) :: NUMBER_OF_ELEMENTS !<On return, the number of elements in the specified mesh
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("MESH_NUMBER_OF_ELEMENTS_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(MESH)) THEN
      IF(MESH%MESH_FINISHED) THEN
        NUMBER_OF_ELEMENTS=MESH%NUMBER_OF_ELEMENTS
      ELSE
        CALL FlagError("Mesh has not been finished",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Mesh is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("MESH_NUMBER_OF_ELEMENTS_GET")
    RETURN
999 ERRORSEXITS("MESH_NUMBER_OF_ELEMENTS_GET",ERR,ERROR)
    RETURN
  END SUBROUTINE MESH_NUMBER_OF_ELEMENTS_GET

  !
  !================================================================================================================================
  !

  !>Changes/sets the number of elements for a mesh. \see OPENCMISS::Iron::cmfe_MeshNumberOfElementsSet
  SUBROUTINE MESH_NUMBER_OF_ELEMENTS_SET(MESH,NUMBER_OF_ELEMENTS,ERR,ERROR,*)

    !Argument variables
    TYPE(MESH_TYPE), POINTER :: MESH !<A pointer to the mesh to set the number of elements for
    INTEGER(INTG), INTENT(IN) :: NUMBER_OF_ELEMENTS !<The number of elements to set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: component_idx
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("MESH_NUMBER_OF_ELEMENTS_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(MESH)) THEN
      IF(NUMBER_OF_ELEMENTS>0) THEN
        IF(MESH%MESH_FINISHED) THEN
          CALL FlagError("Mesh has been finished.",ERR,ERROR,*999)
        ELSE
          IF(NUMBER_OF_ELEMENTS/=MESH%NUMBER_OF_ELEMENTS) THEN
            IF(ASSOCIATED(MESH%TOPOLOGY)) THEN
              DO component_idx=1,MESH%NUMBER_OF_COMPONENTS
                IF(ASSOCIATED(MESH%TOPOLOGY(component_idx)%PTR)) THEN
                  IF(ASSOCIATED(MESH%TOPOLOGY(component_idx)%PTR%ELEMENTS)) THEN
                    IF(MESH%TOPOLOGY(component_idx)%PTR%ELEMENTS%NUMBER_OF_ELEMENTS>0) THEN
!!TODO: Reallocate the elements and copy information.
                      CALL FlagError("Not implemented.",ERR,ERROR,*999)
                    ENDIF
                  ENDIF
                ELSE
                  CALL FlagError("Mesh topology component pointer is not associated.",ERR,ERROR,*999)
                ENDIF
              ENDDO !component_idx
            ELSE
              CALL FlagError("Mesh topology is not associated.",ERR,ERROR,*999)
            ENDIF
            MESH%NUMBER_OF_ELEMENTS=NUMBER_OF_ELEMENTS
          ENDIF
        ENDIF
      ELSE
        LOCAL_ERROR="The specified number of elements ("//TRIM(NUMBER_TO_VSTRING(NUMBER_OF_ELEMENTS,"*",ERR,ERROR))// &
          & ") is invalid. You must have > 0 elements."
        CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Mesh is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("MESH_NUMBER_OF_ELEMENTS_SET")
    RETURN
999 ERRORSEXITS("MESH_NUMBER_OF_ELEMENTS_SET",ERR,ERROR)
    RETURN 1

  END SUBROUTINE MESH_NUMBER_OF_ELEMENTS_SET

  !
  !================================================================================================================================
  !

  !>Changes/sets the surrounding elements calculate flag. \see OPENCMISS::Iron::cmfe_MeshSurroundingElementsCalculateSet
  SUBROUTINE MESH_SURROUNDING_ELEMENTS_CALCULATE_SET(MESH,SURROUNDING_ELEMENTS_CALCULATE_FLAG,ERR,ERROR,*)

    !Argument variables
    TYPE(MESH_TYPE), POINTER :: MESH !<A pointer to the mesh to set the surrounding elements calculate flag for
    LOGICAL, INTENT(IN) :: SURROUNDING_ELEMENTS_CALCULATE_FLAG !<The surrounding elements calculate flag
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string

    ENTERS("MESH_SURROUNDING_ELEMENTS_CALCULATE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(MESH)) THEN
      IF(MESH%MESH_FINISHED) THEN
        CALL FlagError("Mesh has been finished.",ERR,ERROR,*999)
      ELSE
        MESH%SURROUNDING_ELEMENTS_CALCULATE=SURROUNDING_ELEMENTS_CALCULATE_FLAG
      ENDIF
    ELSE
      CALL FlagError("Mesh is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("MESH_SURROUNDING_ELEMENTS_CALCULATE_SET")
    RETURN
999 ERRORSEXITS("MESH_SURROUNDING_ELEMENTS_CALCULATE_SET",ERR,ERROR)
    RETURN 1

  END SUBROUTINE MESH_SURROUNDING_ELEMENTS_CALCULATE_SET

  !
  !================================================================================================================================
  !

  !>Calculates the mesh topology.
  SUBROUTINE MeshTopology_Calculate(topology,err,error,*)

    !Argument variables
    TYPE(MeshComponentTopologyType), POINTER :: topology !<A pointer to the mesh topology to calculate
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables

    ENTERS("MeshTopology_Calculate",err,error,*999)

    IF(ASSOCIATED(topology)) THEN
      !Calculate the nodes used in the mesh
      CALL MeshTopology_NodesCalculate(topology,err,error,*999)
      !Calculate the elements surrounding the nodes in a mesh
      CALL MeshTopology_SurroundingElementsCalculate(topology,err,error,*999)
      !Calculate the number of derivatives at each node in a mesh
      CALL MeshTopology_NodesDerivativesCalculate(topology,err,error,*999)
      !Calculate the number of versions for each derivative at each node in a mesh
      CALL MeshTopology_NodesVersionCalculate(topology,err,error,*999)
      !Calculate the elements surrounding the elements in the mesh
      CALL MeshTopology_ElementsAdjacentElementsCalculate(topology,err,error,*999)
      !Calculate the boundary nodes and elements in the mesh
      CALL MeshTopology_BoundaryCalculate(topology,err,error,*999)
      !Calculate the elements surrounding the elements in the mesh
      CALL MeshTopology_DofsCalculate(topology,err,error,*999)
    ELSE
      CALL FlagError("Topology is not associated",err,error,*999)
    ENDIF

    EXITS("MeshTopology_Calculate")
    RETURN
999 ERRORSEXITS("MeshTopology_Calculate",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_Calculate

  !
  !===============================================================================================================================
  !

  !>Calculates the boundary nodes and elements for a mesh topology.
  SUBROUTINE MeshTopology_BoundaryCalculate(topology,err,error,*)

    !Argument variables
    TYPE(MeshComponentTopologyType), POINTER :: topology !<A pointer to the mesh topology to calculate the boundary for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: elementIdx,localNodeIdx,matchIndex,nodeIdx,xiCoordIdx,xiDirection
    TYPE(BASIS_TYPE), POINTER :: basis
    TYPE(MeshElementsType), POINTER :: elements
    TYPE(MeshNodesType), POINTER :: nodes
    TYPE(VARYING_STRING) :: localError

    ENTERS("MeshTopology_BoundaryCalculate",err,error,*999)

    IF(ASSOCIATED(topology)) THEN
      nodes=>topology%nodes
      IF(ASSOCIATED(nodes)) THEN
        elements=>topology%elements
        IF(ASSOCIATED(elements)) THEN
          DO elementIdx=1,elements%NUMBER_OF_ELEMENTS
            basis=>elements%elements(elementIdx)%basis
            SELECT CASE(basis%type)
            CASE(BASIS_LAGRANGE_HERMITE_TP_TYPE)
              DO xiCoordIdx=-basis%NUMBER_OF_XI_COORDINATES,basis%NUMBER_OF_XI_COORDINATES
                IF(xiCoordIdx/=0) THEN
                  IF(elements%elements(elementIdx)%ADJACENT_ELEMENTS(xiCoordIdx)%NUMBER_OF_ADJACENT_ELEMENTS==0) THEN
                    elements%elements(elementIdx)%BOUNDARY_ELEMENT=.TRUE.
                    IF(xiCoordIdx<0) THEN
                      xiDirection=-xiCoordIdx
                      matchIndex=1
                    ELSE
                      xiDirection=xiCoordIdx
                      matchIndex=BASIS%NUMBER_OF_NODES_XIC(xiCoordIdx)
                    ENDIF
                    DO localNodeIdx=1,BASIS%NUMBER_OF_NODES
                      IF(basis%NODE_POSITION_INDEX(localNodeIdx,XIDIRECTION)==matchIndex) THEN
                        nodeIdx=elements%elements(elementIdx)%MESH_ELEMENT_NODES(localNodeIdx)
                        nodes%nodes(nodeIdx)%boundaryNode=.TRUE.
                      ENDIF
                    ENDDO !nn
                  ENDIF
                ENDIF
              ENDDO !xiCoordIdx
            CASE(BASIS_SIMPLEX_TYPE)
              elements%elements(elementIdx)%BOUNDARY_ELEMENT=.FALSE.
              DO xiCoordIdx=1,basis%NUMBER_OF_XI_COORDINATES
                elements%elements(elementIdx)%BOUNDARY_ELEMENT=elements%elements(elementIdx)%BOUNDARY_ELEMENT.OR. &
                  & elements%elements(elementIdx)%ADJACENT_ELEMENTS(xiCoordIdx)%NUMBER_OF_ADJACENT_ELEMENTS==0
                IF(elements%elements(elementIdx)%ADJACENT_ELEMENTS(xiCoordIdx)%NUMBER_OF_ADJACENT_ELEMENTS==0) THEN
                  DO localNodeIdx=1,basis%NUMBER_OF_NODES
                    IF(basis%NODE_POSITION_INDEX(localNodeIdx,xiCoordIdx)==1) THEN
                      nodeIdx=elements%elements(elementIdx)%MESH_ELEMENT_NODES(localNodeIdx)
                      nodes%nodes(nodeIdx)%boundaryNode=.TRUE.
                    ENDIF
                  ENDDO !localNodeIdx
                ENDIF
              ENDDO !xiCoordIdx
            CASE(BASIS_SERENDIPITY_TYPE)
              CALL FlagError("Not implemented.",err,error,*999)
            CASE(BASIS_AUXILLIARY_TYPE)
              CALL FlagError("Not implemented.",err,error,*999)
            CASE(BASIS_B_SPLINE_TP_TYPE)
              CALL FlagError("Not implemented.",err,error,*999)
            CASE(BASIS_FOURIER_LAGRANGE_HERMITE_TP_TYPE)
              CALL FlagError("Not implemented.",err,error,*999)
            CASE(BASIS_EXTENDED_LAGRANGE_TP_TYPE)
              CALL FlagError("Not implemented.",err,error,*999)
            CASE DEFAULT
              localError="The basis type of "//TRIM(NumberToVString(basis%TYPE,"*",err,error))//" is invalid."
              CALL FlagError(localError,err,error,*999)
            END SELECT
          ENDDO !elementIdx
        ELSE
          CALL FlagError("Topology elements is not associated.",err,error,*999)
        ENDIF
      ELSE
        CALL FlagError("Topology nodes is not associated.",err,error,*999)
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated.",err,error,*999)
    ENDIF

    IF(diagnostics1) THEN
      CALL WriteString(DIAGNOSTIC_OUTPUT_TYPE,"Boundary elements:",err,error,*999)
      CALL WriteStringValue(DIAGNOSTIC_OUTPUT_TYPE,"Number of elements = ",elements%NUMBER_OF_ELEMENTS,err,error,*999)
      DO elementIdx=1,elements%NUMBER_OF_ELEMENTS
        CALL WriteStringValue(DIAGNOSTIC_OUTPUT_TYPE,"Element : ",elementIdx,err,error,*999)
        CALL WriteStringValue(DIAGNOSTIC_OUTPUT_TYPE,"  Boundary element = ",elements%elements(elementIdx)%BOUNDARY_ELEMENT, &
          & err,error,*999)
      ENDDO !elementIdx
      CALL WriteString(DIAGNOSTIC_OUTPUT_TYPE,"Boundary nodes:",err,error,*999)
      CALL WriteStringValue(DIAGNOSTIC_OUTPUT_TYPE,"Number of nodes = ",nodes%numberOfNodes,err,error,*999)
      DO nodeIdx=1,nodes%numberOfNodes
        CALL WriteStringValue(DIAGNOSTIC_OUTPUT_TYPE,"Node : ",nodeIdx,err,error,*999)
        CALL WriteStringValue(DIAGNOSTIC_OUTPUT_TYPE,"  Boundary node = ",nodes%nodes(nodeIdx)%boundaryNode,err,error,*999)
      ENDDO !elementIdx
    ENDIF

    EXITS("MeshTopology_BoundaryCalculate")
    RETURN
999 ERRORSEXITS("MeshTopology_BoundaryCalculate",err,error)
    RETURN 1
  END SUBROUTINE MeshTopology_BoundaryCalculate

  !
  !===============================================================================================================================
  !

  !>Calculates the degrees-of-freedom for a mesh topology.
  SUBROUTINE MeshTopology_DofsCalculate(topology,err,error,*)

    !Argument variables
    TYPE(MeshComponentTopologyType), POINTER :: topology !<A pointer to the mesh topology to calculate the dofs for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: derivativeIdx,nodeIdx,numberOfDofs,versionIdx
    TYPE(MeshDofsType), POINTER :: dofs
    TYPE(MeshNodesType), POINTER :: nodes

    ENTERS("MeshTopology_DofsCalculate",err,error,*999)

    IF(ASSOCIATED(topology)) THEN
      nodes=>topology%nodes
      IF(ASSOCIATED(nodes)) THEN
        dofs=>topology%dofs
        IF(ASSOCIATED(dofs)) THEN
          numberOfDofs=0
          DO nodeIdx=1,nodes%numberOfNodes
            DO derivativeIdx=1,nodes%nodes(nodeIdx)%numberOfDerivatives
              ALLOCATE(nodes%nodes(nodeIdx)%derivatives(derivativeIdx)%dofIndex( &
                & nodes%nodes(nodeIdx)%derivatives(derivativeIdx)%numberOfVersions),STAT=err)
              IF(err/=0) CALL FlagError("Could not allocate mesh topology node derivative version dof index.",err,error,*999)
              DO versionIdx=1,nodes%nodes(nodeIdx)%derivatives(derivativeIdx)%numberOfVersions
                numberOfDofs=numberOfDofs+1
                nodes%nodes(nodeIdx)%derivatives(derivativeIdx)%dofIndex(versionIdx)=numberOfDofs
              ENDDO !versionIdx
            ENDDO !derivativeIdx
          ENDDO !nodeIdx
          dofs%numberOfDofs=numberOfDofs
        ELSE
          CALL FlagError("Topology dofs is not associated.",err,error,*999)
        ENDIF
      ELSE
        CALL FlagError("Topology nodes is not associated.",err,error,*999)
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated.",err,error,*999)
    ENDIF

    EXITS("MeshTopology_DofsCalculate")
    RETURN
999 ERRORSEXITS("MeshTopology_DofsCalculate",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_DofsCalculate

  !
  !===============================================================================================================================
  !

  !>Finalises the dof data structures for a mesh topology and deallocates any memory. \todo pass in dofs
  SUBROUTINE MeshTopology_DofsFinalise(dofs,err,error,*)

    !Argument variables
    TYPE(MeshDofsType), POINTER :: dofs !<A pointer to the mesh topology to finalise the dofs for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables

    ENTERS("MeshTopology_DofsFinalise",err,error,*999)

    IF(ASSOCIATED(dofs)) THEN
      DEALLOCATE(dofs)
    ENDIF

    EXITS("MeshTopology_DofsFinalise")
    RETURN
999 ERRORSEXITS("MeshTopology_DofsFinalise",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_DofsFinalise

  !
  !================================================================================================================================
  !

  !>Initialises the dofs in a given mesh topology.
  SUBROUTINE MeshTopology_DofsInitialise(topology,err,error,*)

    !Argument variables
    TYPE(MeshComponentTopologyType), POINTER :: topology !<A pointer to the mesh topology to initialise the dofs for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: dummyErr
    TYPE(VARYING_STRING) :: dummyError

    ENTERS("MeshTopology_DofsInitialise",err,error,*998)

    IF(ASSOCIATED(topology)) THEN
      IF(ASSOCIATED(topology%dofs)) THEN
        CALL FlagError("Mesh already has topology dofs associated",err,error,*998)
      ELSE
        ALLOCATE(topology%dofs,STAT=err)
        IF(ERR/=0) CALL FlagError("Could not allocate topology dofs",err,error,*999)
        topology%dofs%numberOfDofs=0
        topology%dofs%meshComponentTopology=>topology
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated",err,error,*998)
    ENDIF

    EXITS("MeshTopology_DofsInitialise")
    RETURN
999 CALL MeshTopology_DofsFinalise(topology%dofs,dummyErr,dummyError,*998)
998 ERRORSEXITS("MeshTopology_DofsInitialise",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_DofsInitialise

  !
  !================================================================================================================================
  !

  !>Finishes the process of creating elements for a specified mesh component in a mesh topology. \see OPENCMISS::Iron::cmfe_MeshElementsCreateFinish
  SUBROUTINE MESH_TOPOLOGY_ELEMENTS_CREATE_FINISH(ELEMENTS,ERR,ERROR,*)

    !Argument variables
    TYPE(MeshElementsType), POINTER :: ELEMENTS !<A pointer to the mesh elements to finish creating
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: ne
    TYPE(MESH_TYPE), POINTER :: mesh
    TYPE(MeshComponentTopologyType), POINTER :: meshComponentTopology

    ENTERS("MESH_TOPOLOGY_ELEMENTS_CREATE_FINISH",ERR,ERROR,*999)

    IF(ASSOCIATED(ELEMENTS)) THEN
      IF(ELEMENTS%ELEMENTS_FINISHED) THEN
        CALL FlagError("Mesh elements have already been finished.",ERR,ERROR,*999)
      ELSE
        ELEMENTS%ELEMENTS_FINISHED=.TRUE.
      ENDIF
    ELSE
      CALL FlagError("Mesh elements is not associated.",ERR,ERROR,*999)
    ENDIF

    IF(DIAGNOSTICS1) THEN
      meshComponentTopology=>elements%meshComponentTopology
      IF(ASSOCIATED(meshComponentTopology)) THEN
        mesh=>meshComponentTopology%mesh
        IF(ASSOCIATED(MESH)) THEN
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"Number of global elements = ",MESH%NUMBER_OF_ELEMENTS, &
            & ERR,ERROR,*999)
          DO ne=1,MESH%NUMBER_OF_ELEMENTS
            CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  Element = ",ne,ERR,ERROR,*999)
            CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Global number        = ",ELEMENTS%ELEMENTS(ne)%GLOBAL_NUMBER, &
              & ERR,ERROR,*999)
            CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    User number          = ",ELEMENTS%ELEMENTS(ne)%USER_NUMBER, &
              & ERR,ERROR,*999)
            IF(ASSOCIATED(ELEMENTS%ELEMENTS(ne)%BASIS)) THEN
              CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Basis number         = ",ELEMENTS%ELEMENTS(ne)%BASIS% &
                & USER_NUMBER,ERR,ERROR,*999)
            ELSE
              CALL FlagError("Basis is not associated.",ERR,ERROR,*999)
            ENDIF
            IF(ALLOCATED(ELEMENTS%ELEMENTS(ne)%USER_ELEMENT_NODES)) THEN
              CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,ELEMENTS%ELEMENTS(ne)% BASIS%NUMBER_OF_NODES,8,8, &
                & ELEMENTS%ELEMENTS(ne)%USER_ELEMENT_NODES,'("    User element nodes   =",8(X,I6))','(26X,8(X,I6))', &
                & ERR,ERROR,*999)
            ELSE
              CALL FlagError("User element nodes are not associated.",ERR,ERROR,*999)
            ENDIF
            IF(ALLOCATED(ELEMENTS%ELEMENTS(ne)%GLOBAL_ELEMENT_NODES)) THEN
              CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,ELEMENTS%ELEMENTS(ne)%BASIS%NUMBER_OF_NODES,8,8, &
                & ELEMENTS%ELEMENTS(ne)%GLOBAL_ELEMENT_NODES,'("    Global element nodes =",8(X,I6))','(26X,8(X,I6))', &
                & ERR,ERROR,*999)
            ELSE
              CALL FlagError("Global element nodes are not associated.",ERR,ERROR,*999)
            ENDIF
          ENDDO !ne
        ELSE
          CALL FlagError("Mesh component topology mesh is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Mesh elements mesh component topology is not associated.",ERR,ERROR,*999)
      ENDIF
    ENDIF

    EXITS("MESH_TOPOLOGY_ELEMENTS_CREATE_FINISH")
    RETURN
999 ERRORSEXITS("MESH_TOPOLOGY_ELEMENTS_CREATE_FINISH",ERR,ERROR)
    RETURN 1

  END SUBROUTINE MESH_TOPOLOGY_ELEMENTS_CREATE_FINISH

  !
  !================================================================================================================================
  !

  !>Starts the process of creating elements in the mesh component identified by MESH and component_idx. The elements will be created with a default basis of BASIS. ELEMENTS is the returned pointer to the MESH_ELEMENTS data structure. \see OPENCMISS::Iron::cmfe_MeshElementsCreateStart
  SUBROUTINE MESH_TOPOLOGY_ELEMENTS_CREATE_START(MESH,MESH_COMPONENT_NUMBER,BASIS,ELEMENTS,ERR,ERROR,*)

    !Argument variables
    TYPE(MESH_TYPE), POINTER :: MESH !<A pointer to the mesh to start creating the elements on
    INTEGER(INTG), INTENT(IN) :: MESH_COMPONENT_NUMBER !<The mesh component number
    TYPE(BASIS_TYPE), POINTER :: BASIS !<A pointer to the default basis to use
    TYPE(MeshElementsType), POINTER :: ELEMENTS !<On return, a pointer to the created mesh elements
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR,INSERT_STATUS,ne
    TYPE(VARYING_STRING) :: DUMMY_ERROR,LOCAL_ERROR

    ENTERS("MESH_TOPOLOGY_ELEMENTS_CREATE_START",ERR,ERROR,*999)

    IF(ASSOCIATED(MESH)) THEN
      IF(MESH_COMPONENT_NUMBER>0.AND.MESH_COMPONENT_NUMBER<=MESH%NUMBER_OF_COMPONENTS) THEN
        IF(ASSOCIATED(ELEMENTS)) THEN
          CALL FlagError("Elements is already associated.",ERR,ERROR,*999)
        ELSE
          IF(ASSOCIATED(MESH%TOPOLOGY(MESH_COMPONENT_NUMBER)%PTR)) THEN
            IF(ASSOCIATED(MESH%TOPOLOGY(MESH_COMPONENT_NUMBER)%PTR%ELEMENTS)) THEN
              ELEMENTS=>MESH%TOPOLOGY(MESH_COMPONENT_NUMBER)%PTR%ELEMENTS
              IF(ASSOCIATED(ELEMENTS%ELEMENTS)) THEN
                CALL FlagError("Mesh topology already has elements associated",ERR,ERROR,*998)
              ELSE
                IF(ASSOCIATED(BASIS)) THEN
                  MESH%TOPOLOGY(MESH_COMPONENT_NUMBER)%PTR%meshComponentNumber=MESH_COMPONENT_NUMBER
                  ALLOCATE(ELEMENTS%ELEMENTS(MESH%NUMBER_OF_ELEMENTS),STAT=ERR)
                  IF(ERR/=0) CALL FlagError("Could not allocate individual elements",ERR,ERROR,*999)
                  ELEMENTS%NUMBER_OF_ELEMENTS=MESH%NUMBER_OF_ELEMENTS !Psuedo inheritance of the number of elements
                  CALL TREE_CREATE_START(ELEMENTS%ELEMENTS_TREE,ERR,ERROR,*999)
                  CALL TREE_INSERT_TYPE_SET(ELEMENTS%ELEMENTS_TREE,TREE_NO_DUPLICATES_ALLOWED,ERR,ERROR,*999)
                  CALL TREE_CREATE_FINISH(ELEMENTS%ELEMENTS_TREE,ERR,ERROR,*999)
                  ELEMENTS%ELEMENTS_FINISHED=.FALSE.
                  !Set up the default values and allocate element structures
                  DO ne=1,ELEMENTS%NUMBER_OF_ELEMENTS
                    CALL MESH_TOPOLOGY_ELEMENT_INITIALISE(ELEMENTS%ELEMENTS(ne),ERR,ERROR,*999)
                    ELEMENTS%ELEMENTS(ne)%GLOBAL_NUMBER=ne
                    ELEMENTS%ELEMENTS(ne)%USER_NUMBER=ne
                    CALL TREE_ITEM_INSERT(ELEMENTS%ELEMENTS_TREE,ne,ne,INSERT_STATUS,ERR,ERROR,*999)
                    ELEMENTS%ELEMENTS(ne)%BASIS=>BASIS
                    ALLOCATE(ELEMENTS%ELEMENTS(ne)%USER_ELEMENT_NODES(BASIS%NUMBER_OF_NODES),STAT=ERR)
                    IF(ERR/=0) CALL FlagError("Could not allocate user element nodes",ERR,ERROR,*999)
                    ALLOCATE(ELEMENTS%ELEMENTS(ne)%GLOBAL_ELEMENT_NODES(BASIS%NUMBER_OF_NODES),STAT=ERR)
                    IF(ERR/=0) CALL FlagError("Could not allocate global element nodes",ERR,ERROR,*999)
                    ELEMENTS%ELEMENTS(ne)%USER_ELEMENT_NODES=1
                    ELEMENTS%ELEMENTS(ne)%GLOBAL_ELEMENT_NODES=1
                    ALLOCATE(ELEMENTS%ELEMENTS(ne)%USER_ELEMENT_NODE_VERSIONS(BASIS%MAXIMUM_NUMBER_OF_DERIVATIVES, &
                      & BASIS%NUMBER_OF_NODES),STAT=ERR)
                    IF(ERR/=0) CALL FlagError("Could not allocate global element nodes versions",ERR,ERROR,*999)
                    ELEMENTS%ELEMENTS(ne)%USER_ELEMENT_NODE_VERSIONS = 1
                  ENDDO !ne
                ELSE
                  CALL FlagError("Basis is not associated",ERR,ERROR,*999)
                ENDIF
              ENDIF
            ELSE
              CALL FlagError("Mesh topology elements is not associated",ERR,ERROR,*998)
            ENDIF
          ELSE
            CALL FlagError("Mesh topology is not associated",ERR,ERROR,*998)
          ENDIF
        ENDIF
      ELSE
        LOCAL_ERROR="The specified mesh component number of "//TRIM(NUMBER_TO_VSTRING(MESH_COMPONENT_NUMBER,"*",ERR,ERROR))// &
          & " is invalid. The component number must be between 1 and "// &
          & TRIM(NUMBER_TO_VSTRING(MESH%NUMBER_OF_COMPONENTS,"*",ERR,ERROR))
        CALL FlagError(LOCAL_ERROR,ERR,ERROR,*998)
      ENDIF
    ELSE
      CALL FlagError("Mesh is not associated",ERR,ERROR,*998)
    ENDIF

    EXITS("MESH_TOPOLOGY_ELEMENTS_CREATE_START")
    RETURN
999 CALL MESH_TOPOLOGY_ELEMENTS_FINALISE(ELEMENTS,DUMMY_ERR,DUMMY_ERROR,*998)
998 NULLIFY(ELEMENTS)
    ERRORSEXITS("MESH_TOPOLOGY_ELEMENTS_CREATE_START",ERR,ERROR)
    RETURN 1

  END SUBROUTINE MESH_TOPOLOGY_ELEMENTS_CREATE_START

  !
  !================================================================================================================================
  !

  !>Destroys the elements in a mesh topology. \todo as this is a user routine it should take a mesh pointer like create start and finish? Split this into destroy and finalise?
  SUBROUTINE MESH_TOPOLOGY_ELEMENTS_DESTROY(ELEMENTS,ERR,ERROR,*)

    !Argument variables
    TYPE(MeshElementsType), POINTER :: ELEMENTS !<A pointer to the mesh elements to destroy
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("MESH_TOPOLOGY_ELEMENTS_DESTROY",ERR,ERROR,*999)

    IF(ASSOCIATED(ELEMENTS)) THEN
      CALL MESH_TOPOLOGY_ELEMENTS_FINALISE(ELEMENTS,ERR,ERROR,*999)
    ELSE
      CALL FlagError("Mesh topology is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("MESH_TOPOLOGY_ELEMENTS_DESTROY")
    RETURN
999 ERRORSEXITS("MESH_TOPOLOGY_ELEMENTS_DESTROY",ERR,ERROR)
    RETURN 1
  END SUBROUTINE MESH_TOPOLOGY_ELEMENTS_DESTROY

  !
  !================================================================================================================================
  !

  !>Finalises the given mesh topology element.
  SUBROUTINE MESH_TOPOLOGY_ELEMENT_FINALISE(ELEMENT,ERR,ERROR,*)

    !Argument variables
    TYPE(MESH_ELEMENT_TYPE) :: ELEMENT !<The mesh element to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: nic

    ENTERS("MESH_TOPOLOGY_ELEMENT_FINALISE",ERR,ERROR,*999)

    IF(ALLOCATED(ELEMENT%USER_ELEMENT_NODE_VERSIONS)) DEALLOCATE(ELEMENT%USER_ELEMENT_NODE_VERSIONS)
    IF(ALLOCATED(ELEMENT%USER_ELEMENT_NODES)) DEALLOCATE(ELEMENT%USER_ELEMENT_NODES)
    IF(ALLOCATED(ELEMENT%GLOBAL_ELEMENT_NODES)) DEALLOCATE(ELEMENT%GLOBAL_ELEMENT_NODES)
    IF(ALLOCATED(ELEMENT%MESH_ELEMENT_NODES)) DEALLOCATE(ELEMENT%MESH_ELEMENT_NODES)
    IF(ALLOCATED(ELEMENT%ADJACENT_ELEMENTS)) THEN
      DO nic=LBOUND(ELEMENT%ADJACENT_ELEMENTS,1),UBOUND(ELEMENT%ADJACENT_ELEMENTS,1)
        CALL MESH_ADJACENT_ELEMENT_FINALISE(ELEMENT%ADJACENT_ELEMENTS(nic),ERR,ERROR,*999)
      ENDDO !nic
      DEALLOCATE(ELEMENT%ADJACENT_ELEMENTS)
    ENDIF

    EXITS("MESH_TOPOLOGY_ELEMENT_FINALISE")
    RETURN
999 ERRORSEXITS("MESH_TOPOLOGY_ELEMENT_FINALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE MESH_TOPOLOGY_ELEMENT_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the given mesh topology element.
  SUBROUTINE MESH_TOPOLOGY_ELEMENT_INITIALISE(ELEMENT,ERR,ERROR,*)

    !Argument variables
    TYPE(MESH_ELEMENT_TYPE) :: ELEMENT !<The mesh element to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("MESH_TOPOLOGY_ELEMENT_INITIALISE",ERR,ERROR,*999)

    ELEMENT%USER_NUMBER=0
    ELEMENT%GLOBAL_NUMBER=0
    NULLIFY(ELEMENT%BASIS)
    ELEMENT%BOUNDARY_ELEMENT=.FALSE.

    EXITS("MESH_TOPOLOGY_ELEMENT_INITIALISE")
    RETURN
999 ERRORSEXITS("MESH_TOPOLOGY_ELEMENT_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE MESH_TOPOLOGY_ELEMENT_INITIALISE

  !
  !================================================================================================================================
  !

!!MERGE: Take user number

  !>Gets the basis for a mesh element identified by a given global number. \todo should take user number \see OPENCMISS::Iron::cmfe_MeshElementsBasisGet
  SUBROUTINE MESH_TOPOLOGY_ELEMENTS_ELEMENT_BASIS_GET(GLOBAL_NUMBER,ELEMENTS,BASIS,ERR,ERROR,*)

    !Argument variables
    INTEGER(INTG), INTENT(IN) :: GLOBAL_NUMBER !<The global number of the element to get the basis for
    TYPE(MeshElementsType), POINTER :: ELEMENTS !<A pointer to the elements to get the basis for \todo before number?
    TYPE(BASIS_TYPE), POINTER :: BASIS !<On return, a pointer to the basis to get
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(MESH_ELEMENT_TYPE), POINTER :: ELEMENT
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("MESH_TOPOLOGY_ELEMENTS_ELEMENT_BASIS_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(ELEMENTS)) THEN
      IF(.NOT.ELEMENTS%ELEMENTS_FINISHED) THEN
        CALL FlagError("Elements have been finished",ERR,ERROR,*999)
      ELSE
        IF(GLOBAL_NUMBER>=1.AND.GLOBAL_NUMBER<=ELEMENTS%NUMBER_OF_ELEMENTS) THEN
          ELEMENT=>ELEMENTS%ELEMENTS(GLOBAL_NUMBER)
          BASIS=>ELEMENT%BASIS
        ELSE
          LOCAL_ERROR="Global element number "//TRIM(NUMBER_TO_VSTRING(GLOBAL_NUMBER,"*",ERR,ERROR))// &
            & " is invalid. The limits are 1 to "//TRIM(NUMBER_TO_VSTRING(ELEMENTS%NUMBER_OF_ELEMENTS,"*",ERR,ERROR))
          CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Elements is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("MESH_TOPOLOGY_ELEMENTS_ELEMENT_BASIS_GET")
    RETURN
999 ERRORSEXITS("MESH_TOPOLOGY_ELEMENTS_ELEMENT_BASIS_GET",ERR,ERROR)
    RETURN 1

  END SUBROUTINE MESH_TOPOLOGY_ELEMENTS_ELEMENT_BASIS_GET

  !
  !================================================================================================================================
  !

  !>Changes/sets the basis for a mesh element identified by a given global number. \todo should take user number
  SUBROUTINE MESH_TOPOLOGY_ELEMENTS_ELEMENT_BASIS_SET(GLOBAL_NUMBER,ELEMENTS,BASIS,ERR,ERROR,*)

    !Argument variables
    INTEGER(INTG), INTENT(IN) :: GLOBAL_NUMBER !<The global number of the element to set the basis for
    TYPE(MeshElementsType), POINTER :: ELEMENTS !<A pointer to the elements to set the basis for \todo before number?
    TYPE(BASIS_TYPE), POINTER :: BASIS !<A pointer to the basis to set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG), ALLOCATABLE :: NEW_USER_ELEMENT_NODES(:),NEW_GLOBAL_ELEMENT_NODES(:),NEW_USER_ELEMENT_NODE_VERSIONS(:,:)
    INTEGER(INTG) :: OVERLAPPING_NUMBER_NODES,OVERLAPPING_NUMBER_DERIVATIVES
    TYPE(MESH_ELEMENT_TYPE), POINTER :: ELEMENT
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("MESH_TOPOLOGY_ELEMENTS_ELEMENT_BASIS_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(ELEMENTS)) THEN
      IF(ELEMENTS%ELEMENTS_FINISHED) THEN
        CALL FlagError("Elements have been finished",ERR,ERROR,*999)
      ELSE
        IF(GLOBAL_NUMBER>=1.AND.GLOBAL_NUMBER<=ELEMENTS%NUMBER_OF_ELEMENTS) THEN
          IF(ASSOCIATED(BASIS)) THEN
            ELEMENT=>ELEMENTS%ELEMENTS(GLOBAL_NUMBER)
            IF(ELEMENT%BASIS%NUMBER_OF_NODES/=BASIS%NUMBER_OF_NODES.OR. &
                & ELEMENT%BASIS%MAXIMUM_NUMBER_OF_DERIVATIVES/=BASIS%MAXIMUM_NUMBER_OF_DERIVATIVES) THEN
              !Allocate new user and global element nodes
              ALLOCATE(NEW_USER_ELEMENT_NODES(BASIS%NUMBER_OF_NODES),STAT=ERR)
              IF(ERR/=0) CALL FlagError("Could not allocate new user element nodes",ERR,ERROR,*999)
              ALLOCATE(NEW_GLOBAL_ELEMENT_NODES(BASIS%NUMBER_OF_NODES),STAT=ERR)
              IF(ERR/=0) CALL FlagError("Could not allocate new user element nodes",ERR,ERROR,*999)
              ALLOCATE(NEW_USER_ELEMENT_NODE_VERSIONS(BASIS%MAXIMUM_NUMBER_OF_DERIVATIVES, &
                & BASIS%NUMBER_OF_NODES),STAT=ERR)
              IF(ERR/=0) CALL FlagError("Could not allocate element node versions",ERR,ERROR,*999)

              OVERLAPPING_NUMBER_NODES=MIN(BASIS%NUMBER_OF_NODES,ELEMENT%BASIS%NUMBER_OF_NODES)
              OVERLAPPING_NUMBER_DERIVATIVES=MIN(BASIS%MAXIMUM_NUMBER_OF_DERIVATIVES,ELEMENT%BASIS%MAXIMUM_NUMBER_OF_DERIVATIVES)

              !Set default values
              NEW_USER_ELEMENT_NODE_VERSIONS=1
              NEW_USER_ELEMENT_NODES(OVERLAPPING_NUMBER_NODES+1:)=0
              NEW_GLOBAL_ELEMENT_NODES(OVERLAPPING_NUMBER_NODES+1:)=0
              !Copy previous values
              NEW_USER_ELEMENT_NODES(1:OVERLAPPING_NUMBER_NODES)=ELEMENT%USER_ELEMENT_NODES(1:OVERLAPPING_NUMBER_NODES)
              NEW_GLOBAL_ELEMENT_NODES(1:OVERLAPPING_NUMBER_NODES)=ELEMENT%GLOBAL_ELEMENT_NODES(1:OVERLAPPING_NUMBER_NODES)
              NEW_USER_ELEMENT_NODE_VERSIONS(1:OVERLAPPING_NUMBER_DERIVATIVES,1:OVERLAPPING_NUMBER_NODES)= &
                & ELEMENT%USER_ELEMENT_NODE_VERSIONS(1:OVERLAPPING_NUMBER_DERIVATIVES,1:OVERLAPPING_NUMBER_NODES)

              !Replace arrays with new ones
              CALL MOVE_ALLOC(NEW_USER_ELEMENT_NODE_VERSIONS,ELEMENT%USER_ELEMENT_NODE_VERSIONS)
              CALL MOVE_ALLOC(NEW_USER_ELEMENT_NODES,ELEMENT%USER_ELEMENT_NODES)
              CALL MOVE_ALLOC(NEW_GLOBAL_ELEMENT_NODES,ELEMENT%GLOBAL_ELEMENT_NODES)
            ENDIF
            ELEMENT%BASIS=>BASIS
          ELSE
            CALL FlagError("Basis is not associated",ERR,ERROR,*999)
          ENDIF
        ELSE
          LOCAL_ERROR="Global element number "//TRIM(NUMBER_TO_VSTRING(GLOBAL_NUMBER,"*",ERR,ERROR))// &
            & " is invalid. The limits are 1 to "//TRIM(NUMBER_TO_VSTRING(ELEMENTS%NUMBER_OF_ELEMENTS,"*",ERR,ERROR))
          CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Elements is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("MESH_TOPOLOGY_ELEMENTS_ELEMENT_BASIS_SET")
    RETURN
999 ERRORSEXITS("MESH_TOPOLOGY_ELEMENTS_ELEMENT_BASIS_SET",ERR,ERROR)
    RETURN 1

  END SUBROUTINE MESH_TOPOLOGY_ELEMENTS_ELEMENT_BASIS_SET

  !
  !================================================================================================================================
  !

  !>Returns the adjacent element number for a mesh element identified by a global number. \todo specify by user number not global number \see OPENCMISS::Iron::cmfe_MeshElementsNo
  SUBROUTINE MESH_TOPOLOGY_ELEMENTS_ADJACENT_ELEMENT_GET(GLOBAL_NUMBER,ELEMENTS,ADJACENT_ELEMENT_XI,ADJACENT_ELEMENT_NUMBER, &
    & ERR,ERROR,*)

    !Argument variables
    INTEGER(INTG), INTENT(IN) :: GLOBAL_NUMBER !<The global number of the element to get the adjacent element for
    TYPE(MeshElementsType), POINTER :: ELEMENTS !<A pointer to the elements of a mesh component from which to get the adjacent element from.
    INTEGER(INTG), INTENT(IN) :: ADJACENT_ELEMENT_XI !< The xi coordinate direction to get the adjacent element Note that -xiCoordinateDirection gives the adjacent element before the element in the xiCoordinateDirection'th direction and +xiCoordinateDirection gives the adjacent element after the element in the xiCoordinateDirection'th direction. The xiCoordinateDirection=0 index will give the information on the current element.
    INTEGER(INTG), INTENT(OUT) :: ADJACENT_ELEMENT_NUMBER !<On return, the adjacent element number in the specified xi coordinate direction. Return 0 if the specified element has no adjacent elements in the specified xi coordinate direction.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("MESH_TOPOLOGY_ELEMENTS_ADJACENT_ELEMENT_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(ELEMENTS)) THEN
      IF(.NOT.ELEMENTS%ELEMENTS_FINISHED) THEN
        CALL FlagError("Elements have not been finished",ERR,ERROR,*999)
      ELSE
        IF(GLOBAL_NUMBER>=1.AND.GLOBAL_NUMBER<=ELEMENTS%NUMBER_OF_ELEMENTS) THEN
          IF(ADJACENT_ELEMENT_XI>=-ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%BASIS%NUMBER_OF_XI .AND. &
            & ADJACENT_ELEMENT_XI<=ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%BASIS%NUMBER_OF_XI) THEN
            IF(ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%ADJACENT_ELEMENTS(ADJACENT_ELEMENT_XI)%NUMBER_OF_ADJACENT_ELEMENTS > 0) THEN !\todo Currently returns only the first adjacent element for now as the python binding require the output array size of the adjacent element to be known a-prior. Add routine to first output number of adjacent elements and then loop over all adjacent elements
              ADJACENT_ELEMENT_NUMBER=ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%ADJACENT_ELEMENTS(ADJACENT_ELEMENT_XI)%ADJACENT_ELEMENTS(1)
            ELSE !Return 0 indicating the specified element has no adjacent elements in the specified xi coordinate direction.
              ADJACENT_ELEMENT_NUMBER=0
            ENDIF
          ELSE
            LOCAL_ERROR="The specified adjacent element xi is invalid. The supplied xi is "// &
            & TRIM(NUMBER_TO_VSTRING(ADJACENT_ELEMENT_XI,"*",ERR,ERROR))//" and needs to be >=-"// &
            & TRIM(NUMBER_TO_VSTRING(ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%BASIS%NUMBER_OF_XI,"*",ERR,ERROR))//" and <="// &
            & TRIM(NUMBER_TO_VSTRING(ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%BASIS%NUMBER_OF_XI,"*",ERR,ERROR))//"."
            CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
          ENDIF
        ELSE
          LOCAL_ERROR="Global element number "//TRIM(NUMBER_TO_VSTRING(GLOBAL_NUMBER,"*",ERR,ERROR))// &
            & " is invalid. The limits are 1 to "//TRIM(NUMBER_TO_VSTRING(ELEMENTS%NUMBER_OF_ELEMENTS,"*",ERR,ERROR))
          CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Elements is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("MESH_TOPOLOGY_ELEMENTS_ADJACENT_ELEMENT_GET")
    RETURN
999 ERRORSEXITS("MESH_TOPOLOGY_ELEMENTS_ADJACENT_ELEMENT_GET",ERR,ERROR)
    RETURN 1

  END SUBROUTINE MESH_TOPOLOGY_ELEMENTS_ADJACENT_ELEMENT_GET

  !
  !================================================================================================================================
  !

  !>Gets the element nodes for a mesh element identified by a given global number. \todo specify by user number not global number \see OPENCMISS::Iron::cmfe_MeshElementsNodesGet
  SUBROUTINE MESH_TOPOLOGY_ELEMENTS_ELEMENT_NODES_GET(GLOBAL_NUMBER,ELEMENTS,USER_ELEMENT_NODES,ERR,ERROR,*)

    !Argument variables
    INTEGER(INTG), INTENT(IN) :: GLOBAL_NUMBER !<The global number of the element to set the nodes for
    TYPE(MeshElementsType), POINTER :: ELEMENTS !<A pointer to the elements to set \todo before number?
    INTEGER(INTG), INTENT(OUT) :: USER_ELEMENT_NODES(:) !<On return, USER_ELEMENT_NODES(i). USER_ELEMENT_NODES(i) is the i'th user node number for the element
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("MESH_TOPOLOGY_ELEMENTS_ELEMENT_NODES_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(ELEMENTS)) THEN
      IF(.NOT.ELEMENTS%ELEMENTS_FINISHED) THEN
        CALL FlagError("Elements have not been finished",ERR,ERROR,*999)
      ELSE
        IF(GLOBAL_NUMBER>=1.AND.GLOBAL_NUMBER<=ELEMENTS%NUMBER_OF_ELEMENTS) THEN
          IF(SIZE(USER_ELEMENT_NODES,1)>=SIZE(ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%USER_ELEMENT_NODES,1)) THEN
            USER_ELEMENT_NODES=ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%USER_ELEMENT_NODES
          ELSE
            LOCAL_ERROR="The size of USER_ELEMENT_NODES is too small. The supplied size is "// &
            & TRIM(NUMBER_TO_VSTRING(SIZE(USER_ELEMENT_NODES,1),"*",ERR,ERROR))//" and it needs to be >= "// &
            & TRIM(NUMBER_TO_VSTRING(SIZE(ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%USER_ELEMENT_NODES,1),"*",ERR,ERROR))//"."
            CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
          ENDIF
        ELSE
          LOCAL_ERROR="Global element number "//TRIM(NUMBER_TO_VSTRING(GLOBAL_NUMBER,"*",ERR,ERROR))// &
            & " is invalid. The limits are 1 to "//TRIM(NUMBER_TO_VSTRING(ELEMENTS%NUMBER_OF_ELEMENTS,"*",ERR,ERROR))
          CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Elements is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("MESH_TOPOLOGY_ELEMENTS_ELEMENT_NODES_GET")
    RETURN
999 ERRORSEXITS("MESH_TOPOLOGY_ELEMENTS_ELEMENT_NODES_GET",ERR,ERROR)
    RETURN 1

  END SUBROUTINE MESH_TOPOLOGY_ELEMENTS_ELEMENT_NODES_GET

  !
  !================================================================================================================================
  !

  !>Changes/sets the element nodes for a mesh element identified by a given global number. \todo specify by user number not global number \see OPENCMISS::Iron::cmfe_MeshElementsNodesSet
  SUBROUTINE MESH_TOPOLOGY_ELEMENTS_ELEMENT_NODES_SET(GLOBAL_NUMBER,ELEMENTS,USER_ELEMENT_NODES,ERR,ERROR,*)

    !Argument variables
    INTEGER(INTG), INTENT(IN) :: GLOBAL_NUMBER !<The global number of the element to set the nodes for
    TYPE(MeshElementsType), POINTER :: ELEMENTS !<A pointer to the elements to set \todo before number?
    INTEGER(INTG), INTENT(IN) :: USER_ELEMENT_NODES(:) !<USER_ELEMENT_NODES(i). USER_ELEMENT_NODES(i) is the i'th user node number for the element
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: nn,NUMBER_OF_BAD_NODES,GLOBAL_NODE_NUMBER
    INTEGER(INTG), ALLOCATABLE :: GLOBAL_ELEMENT_NODES(:),BAD_NODES(:)
    LOGICAL :: ELEMENT_NODES_OK,NODE_EXISTS
    TYPE(INTERFACE_TYPE), POINTER :: INTERFACE
    TYPE(MESH_TYPE), POINTER :: mesh
    TYPE(MeshComponentTopologyType), POINTER :: meshComponentTopology
    TYPE(NODES_TYPE), POINTER :: NODES
    TYPE(REGION_TYPE), POINTER :: PARENT_REGION,REGION
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("MESH_TOPOLOGY_ELEMENTS_ELEMENT_NODES_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(ELEMENTS)) THEN
      IF(ELEMENTS%ELEMENTS_FINISHED) THEN
        CALL FlagError("Elements have been finished.",ERR,ERROR,*999)
      ELSE
        IF(GLOBAL_NUMBER>=1.AND.GLOBAL_NUMBER<=ELEMENTS%NUMBER_OF_ELEMENTS) THEN
          IF(SIZE(USER_ELEMENT_NODES,1)==ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%BASIS%NUMBER_OF_NODES) THEN
            meshComponentTopology=>elements%meshComponentTopology
            IF(ASSOCIATED(meshComponentTopology)) THEN
              mesh=>meshComponentTopology%mesh
              IF(ASSOCIATED(mesh)) THEN
                REGION=>MESH%REGION
                IF(ASSOCIATED(REGION)) THEN
                  NODES=>REGION%NODES
                ELSE
                  INTERFACE=>MESH%INTERFACE
                  IF(ASSOCIATED(INTERFACE)) THEN
                    NODES=>INTERFACE%NODES
                    PARENT_REGION=>INTERFACE%PARENT_REGION
                    IF(.NOT.ASSOCIATED(PARENT_REGION)) CALL FlagError("Mesh interface has no parent region.",ERR,ERROR,*999)
                  ELSE
                    CALL FlagError("Elements mesh has no associated region or interface.",ERR,ERROR,*999)
                  ENDIF
                ENDIF
                IF(ASSOCIATED(NODES)) THEN
                  ELEMENT_NODES_OK=.TRUE.
                  ALLOCATE(GLOBAL_ELEMENT_NODES(ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%BASIS%NUMBER_OF_NODES),STAT=ERR)
                  IF(ERR/=0) CALL FlagError("Could not allocate global element nodes.",ERR,ERROR,*999)
                  ALLOCATE(BAD_NODES(ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%BASIS%NUMBER_OF_NODES),STAT=ERR)
                  IF(ERR/=0) CALL FlagError("Could not allocate bad nodes.",ERR,ERROR,*999)
                  NUMBER_OF_BAD_NODES=0
                  DO nn=1,ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%BASIS%NUMBER_OF_NODES
                    CALL NODE_CHECK_EXISTS(NODES,USER_ELEMENT_NODES(nn),NODE_EXISTS,GLOBAL_NODE_NUMBER,ERR,ERROR,*999)
                    IF(NODE_EXISTS) THEN
                      GLOBAL_ELEMENT_NODES(nn)=GLOBAL_NODE_NUMBER
                    ELSE
                      NUMBER_OF_BAD_NODES=NUMBER_OF_BAD_NODES+1
                      BAD_NODES(NUMBER_OF_BAD_NODES)=USER_ELEMENT_NODES(nn)
                      ELEMENT_NODES_OK=.FALSE.
                    ENDIF
                  ENDDO !nn
                  IF(ELEMENT_NODES_OK) THEN
                    ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%USER_ELEMENT_NODES=USER_ELEMENT_NODES
                    ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%GLOBAL_ELEMENT_NODES=GLOBAL_ELEMENT_NODES
                  ELSE
                    IF(NUMBER_OF_BAD_NODES==1) THEN
                      IF(ASSOCIATED(REGION)) THEN
                        LOCAL_ERROR="The element user node number of "//TRIM(NUMBER_TO_VSTRING(BAD_NODES(1),"*",ERR,ERROR))// &
                          & " is not defined in region "//TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))//"."
                      ELSE
                        LOCAL_ERROR="The element user node number of "//TRIM(NUMBER_TO_VSTRING(BAD_NODES(1),"*",ERR,ERROR))// &
                          & " is not defined in interface number "// &
                          & TRIM(NUMBER_TO_VSTRING(INTERFACE%USER_NUMBER,"*",ERR,ERROR))// &
                          & " of parent region number "//TRIM(NUMBER_TO_VSTRING(PARENT_REGION%USER_NUMBER,"*",ERR,ERROR))//"."
                      ENDIF
                    ELSE
                      LOCAL_ERROR="The element user node number of "//TRIM(NUMBER_TO_VSTRING(BAD_NODES(1),"*",ERR,ERROR))
                      DO nn=2,NUMBER_OF_BAD_NODES-1
                        LOCAL_ERROR=LOCAL_ERROR//","//TRIM(NUMBER_TO_VSTRING(BAD_NODES(nn),"*",ERR,ERROR))
                      ENDDO !nn
                      IF(ASSOCIATED(REGION)) THEN
                        LOCAL_ERROR=LOCAL_ERROR//" & "//TRIM(NUMBER_TO_VSTRING(BAD_NODES(NUMBER_OF_BAD_NODES),"*",ERR,ERROR))// &
                          & " are not defined in region number "//TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))//"."
                      ELSE
                        LOCAL_ERROR=LOCAL_ERROR//" & "//TRIM(NUMBER_TO_VSTRING(BAD_NODES(NUMBER_OF_BAD_NODES),"*",ERR,ERROR))// &
                          & " are not defined in interface number "// &
                          & TRIM(NUMBER_TO_VSTRING(INTERFACE%USER_NUMBER,"*",ERR,ERROR))//" of parent region number "// &
                          &  TRIM(NUMBER_TO_VSTRING(PARENT_REGION%USER_NUMBER,"*",ERR,ERROR))//"."
                      ENDIF
                    ENDIF
                    CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                  ENDIF
                ELSE
                  IF(ASSOCIATED(REGION)) THEN
                    CALL FlagError("The elements mesh region does not have any associated nodes.",ERR,ERROR,*999)
                  ELSE
                    CALL FlagError("The elements mesh interface does not have any associated nodes.",ERR,ERROR,*999)
                  ENDIF
                ENDIF
              ELSE
                CALL FlagError("The mesh component topology mesh is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FlagError("The elements mesh component topology is not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Number of element nodes does not match number of basis nodes for this element.",ERR,ERROR,*999)
          ENDIF
        ELSE
          LOCAL_ERROR="The specified global element number of "//TRIM(NUMBER_TO_VSTRING(GLOBAL_NUMBER,"*",ERR,ERROR))// &
            & " is invalid. The global element number should be between 1 and "// &
            & TRIM(NUMBER_TO_VSTRING(ELEMENTS%NUMBER_OF_ELEMENTS,"*",ERR,ERROR))//"."
          CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Elements is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("MESH_TOPOLOGY_ELEMENTS_ELEMENT_NODES_SET")
    RETURN
999 ERRORSEXITS("MESH_TOPOLOGY_ELEMENTS_ELEMENT_NODES_SET",ERR,ERROR)
    RETURN 1

  END SUBROUTINE MESH_TOPOLOGY_ELEMENTS_ELEMENT_NODES_SET

  !
  !================================================================================================================================
  !

  !>Changes/sets an element node's version for a mesh element identified by a given global number. \todo specify by user number not global number \see OPENCMISS::Iron::cmfe_MeshElementsNodesSet
  SUBROUTINE MeshElements_ElementNodeVersionSet(GLOBAL_NUMBER,ELEMENTS,VERSION_NUMBER,DERIVATIVE_NUMBER, &
      & USER_ELEMENT_NODE_INDEX,ERR,ERROR,*)

    !Argument variables
    INTEGER(INTG), INTENT(IN) :: GLOBAL_NUMBER !<The global number of the element to set the nodes for
    TYPE(MeshElementsType), POINTER :: ELEMENTS !<A pointer to the elements to set \todo before number?
    INTEGER(INTG), INTENT(IN) :: VERSION_NUMBER !<The version number of the specified element node to set.
    INTEGER(INTG), INTENT(IN) :: DERIVATIVE_NUMBER !<The derivative number of the specified element node to set.
    INTEGER(INTG), INTENT(IN) :: USER_ELEMENT_NODE_INDEX !< The node index of the specified element node to set a version for.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string

    !Local Variables
    TYPE(INTERFACE_TYPE), POINTER :: INTERFACE
    TYPE(MESH_TYPE), POINTER :: MESH
    TYPE(MeshComponentTopologyType), POINTER :: meshComponentTopology
    TYPE(NODES_TYPE), POINTER :: NODES
    TYPE(REGION_TYPE), POINTER :: PARENT_REGION,REGION
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("MeshElements_ElementNodeVersionSet",ERR,ERROR,*999)

    IF(ASSOCIATED(ELEMENTS)) THEN
      IF(ELEMENTS%ELEMENTS_FINISHED) THEN
        CALL FlagError("Elements have been finished.",ERR,ERROR,*999)
      ELSE
        IF(GLOBAL_NUMBER>=1.AND.GLOBAL_NUMBER<=ELEMENTS%NUMBER_OF_ELEMENTS) THEN
          IF(USER_ELEMENT_NODE_INDEX>=1.AND.USER_ELEMENT_NODE_INDEX<=ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%BASIS%NUMBER_OF_NODES) THEN
            meshComponentTopology=>elements%meshComponentTopology
            IF(ASSOCIATED(meshComponentTopology)) THEN
              mesh=>meshComponentTopology%mesh
              IF(ASSOCIATED(mesh)) THEN
                REGION=>mesh%REGION
                IF(ASSOCIATED(REGION)) THEN
                  NODES=>REGION%NODES
                ELSE
                  INTERFACE=>mesh%INTERFACE
                  IF(ASSOCIATED(INTERFACE)) THEN
                    NODES=>INTERFACE%NODES
                    PARENT_REGION=>INTERFACE%PARENT_REGION
                    IF(.NOT.ASSOCIATED(PARENT_REGION)) CALL FlagError("Mesh interface has no parent region.",ERR,ERROR,*999)
                  ELSE
                    CALL FlagError("Elements mesh has no associated region or interface.",ERR,ERROR,*999)
                  ENDIF
                ENDIF
                IF(DERIVATIVE_NUMBER>=1.AND.DERIVATIVE_NUMBER<=ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%BASIS% &
                  & NUMBER_OF_DERIVATIVES(USER_ELEMENT_NODE_INDEX)) THEN !Check if the specified derivative exists
                  IF(VERSION_NUMBER>=1) THEN !Check if the specified version is greater than 1
                    ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%USER_ELEMENT_NODE_VERSIONS(DERIVATIVE_NUMBER,USER_ELEMENT_NODE_INDEX) &
                      & = VERSION_NUMBER
                    !\todo : There is redunancy in USER_ELEMENT_NODE_VERSIONS since it was allocated in MESH_TOPOLOGY_ELEMENTS_CREATE_START based on MAXIMUM_NUMBER_OF_DERIVATIVES for that elements basis:ALLOCATE(ELEMENTS%ELEMENTS(ne)%USER_ELEMENT_NODE_VERSIONS(BASIS%MAXIMUM_NUMBER_OF_DERIVATIVES,BASIS%NUMBER_OF_NODES),STAT=ERR)
                  ELSE
                    LOCAL_ERROR="The specified node version number of "//TRIM(NUMBER_TO_VSTRING(VERSION_NUMBER,"*", &
                      & ERR,ERROR))//" is invalid. The element node index should be greater than 1."
                    CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                  ENDIF
                ELSE
                  LOCAL_ERROR="The specified node derivative number of "//TRIM(NUMBER_TO_VSTRING(DERIVATIVE_NUMBER,"*", &
                    & ERR,ERROR))//" is invalid. The element node derivative index should be between 1 and "// &
                    & TRIM(NUMBER_TO_VSTRING(ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%BASIS%NUMBER_OF_DERIVATIVES( &
                    & USER_ELEMENT_NODE_INDEX),"*",ERR,ERROR))//"."
                  CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FlagError("The mesh component topology mesh is not associated.",err,error,*999)
              ENDIF
            ELSE
              CALL FlagError("The elements mesh component topology is not associated.",err,error,*999)
            ENDIF
          ELSE
            LOCAL_ERROR="The specified element node index of "//TRIM(NUMBER_TO_VSTRING(USER_ELEMENT_NODE_INDEX,"*",ERR,ERROR))// &
              & " is invalid. The element node index should be between 1 and "// &
              & TRIM(NUMBER_TO_VSTRING(ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%BASIS%NUMBER_OF_NODES,"*",ERR,ERROR))//"."
            CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
          ENDIF
        ELSE
          LOCAL_ERROR="The specified global element number of "//TRIM(NUMBER_TO_VSTRING(GLOBAL_NUMBER,"*",ERR,ERROR))// &
            & " is invalid. The global element number should be between 1 and "// &
            & TRIM(NUMBER_TO_VSTRING(ELEMENTS%NUMBER_OF_ELEMENTS,"*",ERR,ERROR))//"."
          CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Elements is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("MeshElements_ElementNodeVersionSet")
    RETURN
999 ERRORSEXITS("MeshElements_ElementNodeVersionSet",ERR,ERROR)
    RETURN 1

  END SUBROUTINE MeshElements_ElementNodeVersionSet

  !
  !================================================================================================================================
  !

 !>Calculates the element numbers surrounding an element in a mesh topology.
  SUBROUTINE MeshTopology_ElementsAdjacentElementsCalculate(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(MeshComponentTopologyType), POINTER :: TOPOLOGY !<A pointer to the mesh topology to calculate the elements adjacent to elements for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: j,ne,ne1,nep1,ni,nic,nn,nn1,nn2,nn3,node_idx,np,np1,DUMMY_ERR,FACE_XI(2),FACE_XIC(3),NODE_POSITION_INDEX(4)
    INTEGER(INTG) :: xi_direction,direction_index,xi_dir_check,xi_dir_search,NUMBER_NODE_MATCHES
    INTEGER(INTG) :: NUMBER_SURROUNDING,NUMBER_OF_NODES_XIC(4)
    INTEGER(INTG), ALLOCATABLE :: NODE_MATCHES(:),ADJACENT_ELEMENTS(:)
    LOGICAL :: XI_COLLAPSED,FACE_COLLAPSED(-3:3),SUBSET
    TYPE(LIST_TYPE), POINTER :: NODE_MATCH_LIST
    TYPE(LIST_PTR_TYPE) :: ADJACENT_ELEMENTS_LIST(-4:4)
    TYPE(BASIS_TYPE), POINTER :: BASIS
    TYPE(VARYING_STRING) :: DUMMY_ERROR,LOCAL_ERROR

    NULLIFY(NODE_MATCH_LIST)
    DO nic=-4,4
      NULLIFY(ADJACENT_ELEMENTS_LIST(nic)%PTR)
    ENDDO !nic

    ENTERS("MeshTopology_ElementsAdjacentElementsCalculate",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      IF(ASSOCIATED(TOPOLOGY%NODES)) THEN
        IF(ASSOCIATED(TOPOLOGY%ELEMENTS)) THEN
          !Loop over the global elements in the mesh
          DO ne=1,TOPOLOGY%ELEMENTS%NUMBER_OF_ELEMENTS
            !%%%% first we initialize lists that are required to find the adjacent elements list
            BASIS=>TOPOLOGY%ELEMENTS%ELEMENTS(ne)%BASIS
            DO nic=-BASIS%NUMBER_OF_XI_COORDINATES,BASIS%NUMBER_OF_XI_COORDINATES
              NULLIFY(ADJACENT_ELEMENTS_LIST(nic)%PTR)
              CALL LIST_CREATE_START(ADJACENT_ELEMENTS_LIST(nic)%PTR,ERR,ERROR,*999)
              CALL LIST_DATA_TYPE_SET(ADJACENT_ELEMENTS_LIST(nic)%PTR,LIST_INTG_TYPE,ERR,ERROR,*999)
              CALL LIST_INITIAL_SIZE_SET(ADJACENT_ELEMENTS_LIST(nic)%PTR,5,ERR,ERROR,*999)
              CALL LIST_CREATE_FINISH(ADJACENT_ELEMENTS_LIST(nic)%PTR,ERR,ERROR,*999)
            ENDDO !ni
            NUMBER_OF_NODES_XIC=1
            NUMBER_OF_NODES_XIC(1:BASIS%NUMBER_OF_XI_COORDINATES)=BASIS%NUMBER_OF_NODES_XIC(1:BASIS%NUMBER_OF_XI_COORDINATES)
            !Place the current element in the surrounding list
            CALL LIST_ITEM_ADD(ADJACENT_ELEMENTS_LIST(0)%PTR,TOPOLOGY%ELEMENTS%ELEMENTS(ne)%GLOBAL_NUMBER,ERR,ERROR,*999)
            SELECT CASE(BASIS%TYPE)
            CASE(BASIS_LAGRANGE_HERMITE_TP_TYPE)
              !Determine the collapsed "faces" if any
              NODE_POSITION_INDEX=1
              !Loop over the face normals of the element
              DO ni=1,BASIS%NUMBER_OF_XI
                !Determine the xi directions that lie in this xi direction
                FACE_XI(1)=OTHER_XI_DIRECTIONS3(ni,2,1)
                FACE_XI(2)=OTHER_XI_DIRECTIONS3(ni,3,1)
                !Reset the node_position_index in this xi direction
                NODE_POSITION_INDEX(ni)=1
                !Loop over the two faces with this normal
                DO direction_index=-1,1,2
                  xi_direction=direction_index*ni
                  FACE_COLLAPSED(xi_direction)=.FALSE.
                  DO j=1,2
                    xi_dir_check=FACE_XI(j)
                    IF(xi_dir_check<=BASIS%NUMBER_OF_XI) THEN
                      xi_dir_search=FACE_XI(3-j)
                      NODE_POSITION_INDEX(xi_dir_search)=1
                      XI_COLLAPSED=.TRUE.
                      DO WHILE(NODE_POSITION_INDEX(xi_dir_search)<=NUMBER_OF_NODES_XIC(xi_dir_search).AND.XI_COLLAPSED)
                        !Get the first local node along the xi check direction
                        NODE_POSITION_INDEX(xi_dir_check)=1
                        nn1=BASIS%NODE_POSITION_INDEX_INV(NODE_POSITION_INDEX(1),NODE_POSITION_INDEX(2),NODE_POSITION_INDEX(3),1)
                        !Get the second local node along the xi check direction
                        NODE_POSITION_INDEX(xi_dir_check)=2
                        nn2=BASIS%NODE_POSITION_INDEX_INV(NODE_POSITION_INDEX(1),NODE_POSITION_INDEX(2),NODE_POSITION_INDEX(3),1)
                        IF(nn1/=0.AND.nn2/=0) THEN
                          IF(TOPOLOGY%ELEMENTS%ELEMENTS(ne)%MESH_ELEMENT_NODES(nn1)/= &
                            & TOPOLOGY%ELEMENTS%ELEMENTS(ne)%MESH_ELEMENT_NODES(nn2)) XI_COLLAPSED=.TRUE.
                        ENDIF
                        NODE_POSITION_INDEX(xi_dir_search)=NODE_POSITION_INDEX(xi_dir_search)+1
                      ENDDO !xi_dir_search
                      IF(XI_COLLAPSED) FACE_COLLAPSED(xi_direction)=.TRUE.
                    ENDIF
                  ENDDO !j
                  NODE_POSITION_INDEX(ni)=NUMBER_OF_NODES_XIC(ni)
                ENDDO !direction_index
              ENDDO !ni
              !Loop over the xi directions and calculate the surrounding elements
              DO ni=1,BASIS%NUMBER_OF_XI
                !Determine the xi directions that lie in this xi direction
                FACE_XI(1)=OTHER_XI_DIRECTIONS3(ni,2,1)
                FACE_XI(2)=OTHER_XI_DIRECTIONS3(ni,3,1)
                !Loop over the two faces
                DO direction_index=-1,1,2
                  xi_direction=direction_index*ni
                  !Find nodes in the element on the appropriate face/line/point
                  NULLIFY(NODE_MATCH_LIST)
                  CALL LIST_CREATE_START(NODE_MATCH_LIST,ERR,ERROR,*999)
                  CALL LIST_DATA_TYPE_SET(NODE_MATCH_LIST,LIST_INTG_TYPE,ERR,ERROR,*999)

                  CALL LIST_INITIAL_SIZE_SET(NODE_MATCH_LIST,16,ERR,ERROR,*999)
                  CALL LIST_CREATE_FINISH(NODE_MATCH_LIST,ERR,ERROR,*999)
                  IF(direction_index==-1) THEN
                    NODE_POSITION_INDEX(ni)=1
                  ELSE
                    NODE_POSITION_INDEX(ni)=NUMBER_OF_NODES_XIC(ni)
                  ENDIF
                  !If the face is collapsed then don't look in this xi direction. The exception is if the opposite face is also
                  !collpased. This may indicate that we have a funny element in non-rc coordinates that goes around the central
                  !axis back to itself
                  IF(FACE_COLLAPSED(xi_direction).AND..NOT.FACE_COLLAPSED(-xi_direction)) THEN
                    !Do nothing - the match lists are already empty
                  ELSE
                    !Find the nodes to match and add them to the node match list
                    DO nn1=1,NUMBER_OF_NODES_XIC(FACE_XI(1))
                      NODE_POSITION_INDEX(FACE_XI(1))=nn1
                      DO nn2=1,NUMBER_OF_NODES_XIC(FACE_XI(2))
                        NODE_POSITION_INDEX(FACE_XI(2))=nn2
                        nn=BASIS%NODE_POSITION_INDEX_INV(NODE_POSITION_INDEX(1),NODE_POSITION_INDEX(2),NODE_POSITION_INDEX(3),1)
                        IF(nn/=0) THEN
                          np=TOPOLOGY%ELEMENTS%ELEMENTS(ne)%MESH_ELEMENT_NODES(nn)
                          CALL LIST_ITEM_ADD(NODE_MATCH_LIST,np,ERR,ERROR,*999)
                        ENDIF
                      ENDDO !nn2
                    ENDDO !nn1
                  ENDIF
                  CALL LIST_REMOVE_DUPLICATES(NODE_MATCH_LIST,ERR,ERROR,*999)
                  CALL LIST_DETACH_AND_DESTROY(NODE_MATCH_LIST,NUMBER_NODE_MATCHES,NODE_MATCHES,ERR,ERROR,*999)
                  NUMBER_SURROUNDING=0
                  IF(NUMBER_NODE_MATCHES>0) THEN
                    !Find list of elements surrounding those nodes
                    np1=NODE_MATCHES(1)
                    DO nep1=1,TOPOLOGY%NODES%NODES(np1)%numberOfSurroundingElements
                      ne1=TOPOLOGY%NODES%NODES(np1)%surroundingElements(nep1)
                      IF(ne1/=ne) THEN !Don't want the current element
                        ! grab the nodes list for current and this surrouding elements
                        ! current face : NODE_MATCHES
                        ! candidate elem : TOPOLOGY%ELEMENTS%ELEMENTS(ne1)%MESH_ELEMENT_NODES ! should this be GLOBAL_ELEMENT_NODES?
                        ! if all of current face belongs to the candidate element, we will have found the neighbour
                        CALL LIST_SUBSET_OF(NODE_MATCHES(1:NUMBER_NODE_MATCHES),TOPOLOGY%ELEMENTS%ELEMENTS(ne1)% &
                          & MESH_ELEMENT_NODES,SUBSET,ERR,ERROR,*999)
                        IF(SUBSET) THEN
                          CALL LIST_ITEM_ADD(ADJACENT_ELEMENTS_LIST(xi_direction)%PTR,ne1,ERR,ERROR,*999)
                          NUMBER_SURROUNDING=NUMBER_SURROUNDING+1
                        ENDIF
                      ENDIF
                    ENDDO !nep1
                  ENDIF
                  IF(ALLOCATED(NODE_MATCHES)) DEALLOCATE(NODE_MATCHES)
                ENDDO !direction_index
              ENDDO !ni
            CASE(BASIS_SIMPLEX_TYPE)
              !Loop over the xi coordinates and calculate the surrounding elements
              DO nic=1,BASIS%NUMBER_OF_XI_COORDINATES
                !Find the other coordinates of the face/line/point
                FACE_XIC(1)=OTHER_XI_DIRECTIONS4(nic,1)
                FACE_XIC(2)=OTHER_XI_DIRECTIONS4(nic,2)
                FACE_XIC(3)=OTHER_XI_DIRECTIONS4(nic,3)
                !Find nodes in the element on the appropriate face/line/point
                NULLIFY(NODE_MATCH_LIST)
                CALL LIST_CREATE_START(NODE_MATCH_LIST,ERR,ERROR,*999)
                CALL LIST_DATA_TYPE_SET(NODE_MATCH_LIST,LIST_INTG_TYPE,ERR,ERROR,*999)
                CALL LIST_INITIAL_SIZE_SET(NODE_MATCH_LIST,16,ERR,ERROR,*999)
                CALL LIST_CREATE_FINISH(NODE_MATCH_LIST,ERR,ERROR,*999)
                NODE_POSITION_INDEX(nic)=1 !Furtherest away from node with the nic'th coordinate
                !Find the nodes to match and add them to the node match list
                DO nn1=1,NUMBER_OF_NODES_XIC(FACE_XIC(1))
                  NODE_POSITION_INDEX(FACE_XIC(1))=nn1
                  DO nn2=1,NUMBER_OF_NODES_XIC(FACE_XIC(2))
                    NODE_POSITION_INDEX(FACE_XIC(2))=nn2
                    DO nn3=1,NUMBER_OF_NODES_XIC(FACE_XIC(3))
                      NODE_POSITION_INDEX(FACE_XIC(3))=nn3
                      nn=BASIS%NODE_POSITION_INDEX_INV(NODE_POSITION_INDEX(1),NODE_POSITION_INDEX(2),NODE_POSITION_INDEX(3), &
                        NODE_POSITION_INDEX(4))
                      IF(nn/=0) THEN
                        np=TOPOLOGY%ELEMENTS%ELEMENTS(ne)%MESH_ELEMENT_NODES(nn)
                        CALL LIST_ITEM_ADD(NODE_MATCH_LIST,np,ERR,ERROR,*999)
                      ENDIF
                    ENDDO !nn3
                  ENDDO !nn2
                ENDDO !nn1
                CALL LIST_REMOVE_DUPLICATES(NODE_MATCH_LIST,ERR,ERROR,*999)
                CALL LIST_DETACH_AND_DESTROY(NODE_MATCH_LIST,NUMBER_NODE_MATCHES,NODE_MATCHES,ERR,ERROR,*999)
                IF(NUMBER_NODE_MATCHES>0) THEN
                  !Find list of elements surrounding those nodes
                  DO node_idx=1,NUMBER_NODE_MATCHES
                    np1=NODE_MATCHES(node_idx)
                    DO nep1=1,TOPOLOGY%NODES%NODES(np1)%numberOfSurroundingElements
                      ne1=TOPOLOGY%NODES%NODES(np1)%surroundingElements(nep1)
                      IF(ne1/=ne) THEN !Don't want the current element
                        ! grab the nodes list for current and this surrouding elements
                        ! current face : NODE_MATCHES
                        ! candidate elem : TOPOLOGY%ELEMENTS%ELEMENTS(ne1)%MESH_ELEMENT_NODES
                        ! if all of current face belongs to the candidate element, we will have found the neighbour
                        CALL LIST_SUBSET_OF(NODE_MATCHES(1:NUMBER_NODE_MATCHES),TOPOLOGY%ELEMENTS%ELEMENTS(ne1)% &
                          & MESH_ELEMENT_NODES,SUBSET,ERR,ERROR,*999)
                        IF(SUBSET) THEN
                          CALL LIST_ITEM_ADD(ADJACENT_ELEMENTS_LIST(nic)%PTR,ne1,ERR,ERROR,*999)
                        ENDIF
                      ENDIF
                    ENDDO !nep1
                  ENDDO !node_idx
                ENDIF
                IF(ALLOCATED(NODE_MATCHES)) DEALLOCATE(NODE_MATCHES)
              ENDDO !nic
            CASE(BASIS_SERENDIPITY_TYPE)
              CALL FlagError("Not implemented.",ERR,ERROR,*999)
            CASE(BASIS_AUXILLIARY_TYPE)
              CALL FlagError("Not implemented.",ERR,ERROR,*999)
            CASE(BASIS_B_SPLINE_TP_TYPE)
              CALL FlagError("Not implemented.",ERR,ERROR,*999)
            CASE(BASIS_FOURIER_LAGRANGE_HERMITE_TP_TYPE)
              CALL FlagError("Not implemented.",ERR,ERROR,*999)
            CASE(BASIS_EXTENDED_LAGRANGE_TP_TYPE)
              CALL FlagError("Not implemented.",ERR,ERROR,*999)
            CASE DEFAULT
              LOCAL_ERROR="The basis type of "//TRIM(NUMBER_TO_VSTRING(BASIS%TYPE,"*",ERR,ERROR))// &
                & " is invalid."
              CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
            END SELECT
            !Set the surrounding elements for this element
            ALLOCATE(TOPOLOGY%ELEMENTS%ELEMENTS(ne)%ADJACENT_ELEMENTS(-BASIS%NUMBER_OF_XI_COORDINATES: &
              & BASIS%NUMBER_OF_XI_COORDINATES),STAT=ERR)
            IF(ERR/=0) CALL FlagError("Could not allocate adjacent elements.",ERR,ERROR,*999)
            DO nic=-BASIS%NUMBER_OF_XI_COORDINATES,BASIS%NUMBER_OF_XI_COORDINATES
              CALL MESH_ADJACENT_ELEMENT_INITIALISE(TOPOLOGY%ELEMENTS%ELEMENTS(ne)%ADJACENT_ELEMENTS(nic),ERR,ERROR,*999)
              CALL LIST_REMOVE_DUPLICATES(ADJACENT_ELEMENTS_LIST(nic)%PTR,ERR,ERROR,*999)
              CALL LIST_DETACH_AND_DESTROY(ADJACENT_ELEMENTS_LIST(nic)%PTR,TOPOLOGY%ELEMENTS%ELEMENTS(ne)% &
                & ADJACENT_ELEMENTS(nic)%NUMBER_OF_ADJACENT_ELEMENTS,ADJACENT_ELEMENTS,ERR,ERROR,*999)
              ALLOCATE(TOPOLOGY%ELEMENTS%ELEMENTS(ne)%ADJACENT_ELEMENTS(nic)%ADJACENT_ELEMENTS(TOPOLOGY%ELEMENTS%ELEMENTS(ne)% &
                ADJACENT_ELEMENTS(nic)%NUMBER_OF_ADJACENT_ELEMENTS),STAT=ERR)
              IF(ERR/=0) CALL FlagError("Could not allocate element adjacent elements.",ERR,ERROR,*999)
              TOPOLOGY%ELEMENTS%ELEMENTS(ne)%ADJACENT_ELEMENTS(nic)%ADJACENT_ELEMENTS(1:TOPOLOGY%ELEMENTS%ELEMENTS(ne)% &
                ADJACENT_ELEMENTS(nic)%NUMBER_OF_ADJACENT_ELEMENTS) = ADJACENT_ELEMENTS(1:TOPOLOGY%ELEMENTS% &
                & ELEMENTS(ne)%ADJACENT_ELEMENTS(nic)%NUMBER_OF_ADJACENT_ELEMENTS)
              IF(ALLOCATED(ADJACENT_ELEMENTS)) DEALLOCATE(ADJACENT_ELEMENTS)
            ENDDO !nic
          ENDDO !ne
        ELSE
          CALL FlagError("Mesh topology elements is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Mesh topology nodes is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Mesh topology is not allocated.",ERR,ERROR,*999)
    ENDIF

    IF(DIAGNOSTICS1) THEN
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"Number of elements = ",TOPOLOGY%ELEMENTS%NUMBER_OF_ELEMENTS,ERR,ERROR,*999)
      DO ne=1,TOPOLOGY%ELEMENTS%NUMBER_OF_ELEMENTS
        BASIS=>TOPOLOGY%ELEMENTS%ELEMENTS(ne)%BASIS
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  Global element number : ",ne,ERR,ERROR,*999)
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    Number of xi coordinates = ",BASIS%NUMBER_OF_XI_COORDINATES, &
          & ERR,ERROR,*999)
        DO nic=-BASIS%NUMBER_OF_XI_COORDINATES,BASIS%NUMBER_OF_XI_COORDINATES
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"      Xi coordinate : ",nic,ERR,ERROR,*999)
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"        Number of adjacent elements = ", &
            & TOPOLOGY%ELEMENTS%ELEMENTS(ne)%ADJACENT_ELEMENTS(nic)%NUMBER_OF_ADJACENT_ELEMENTS,ERR,ERROR,*999)
          IF(TOPOLOGY%ELEMENTS%ELEMENTS(ne)%ADJACENT_ELEMENTS(nic)%NUMBER_OF_ADJACENT_ELEMENTS>0) THEN
            CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1,TOPOLOGY%ELEMENTS%ELEMENTS(ne)% &
              & ADJACENT_ELEMENTS(nic)%NUMBER_OF_ADJACENT_ELEMENTS,8,8,TOPOLOGY%ELEMENTS%ELEMENTS(ne)%ADJACENT_ELEMENTS(nic)% &
              & ADJACENT_ELEMENTS,'("        Adjacent elements :",8(X,I8))','(30x,8(X,I8))',ERR,ERROR,*999)
          ENDIF
        ENDDO !nic
      ENDDO !ne
    ENDIF

    EXITS("MeshTopology_ElementsAdjacentElementsCalculate")
    RETURN
999 IF(ALLOCATED(NODE_MATCHES)) DEALLOCATE(NODE_MATCHES)
    IF(ALLOCATED(ADJACENT_ELEMENTS)) DEALLOCATE(ADJACENT_ELEMENTS)
    IF(ASSOCIATED(NODE_MATCH_LIST)) CALL LIST_DESTROY(NODE_MATCH_LIST,DUMMY_ERR,DUMMY_ERROR,*998)
998 DO nic=-4,4
      IF(ASSOCIATED(ADJACENT_ELEMENTS_LIST(nic)%PTR)) CALL LIST_DESTROY(ADJACENT_ELEMENTS_LIST(nic)%PTR,DUMMY_ERR,DUMMY_ERROR,*997)
    ENDDO !ni
997 ERRORS("MeshTopology_ElementsAdjacentElementsCalculate",ERR,ERROR)
    EXITS("MeshTopology_ElementsAdjacentElementsCalculate")
    RETURN 1

  END SUBROUTINE MeshTopology_ElementsAdjacentElementsCalculate

  !
  !================================================================================================================================
  !

  !>Finalises the elements data structures for a mesh topology and deallocates any memory. \todo pass in elements
  SUBROUTINE MESH_TOPOLOGY_ELEMENTS_FINALISE(ELEMENTS,ERR,ERROR,*)

    !Argument variables
    TYPE(MeshElementsType), POINTER :: ELEMENTS !<A pointer to the mesh topology to finalise the elements for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: ne

    ENTERS("MESH_TOPOLOGY_ELEMENTS_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(ELEMENTS)) THEN
      DO ne=1,ELEMENTS%NUMBER_OF_ELEMENTS
        CALL MESH_TOPOLOGY_ELEMENT_FINALISE(ELEMENTS%ELEMENTS(ne),ERR,ERROR,*999)
      ENDDO !ne
      DEALLOCATE(ELEMENTS%ELEMENTS)
      IF(ASSOCIATED(ELEMENTS%ELEMENTS_TREE)) CALL TREE_DESTROY(ELEMENTS%ELEMENTS_TREE,ERR,ERROR,*999)
      DEALLOCATE(ELEMENTS)
    ENDIF

    EXITS("MESH_TOPOLOGY_ELEMENTS_FINALISE")
    RETURN
999 ERRORSEXITS("MESH_TOPOLOGY_ELEMENTS_FINALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE MESH_TOPOLOGY_ELEMENTS_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the elements in a given mesh topology. \todo finalise on error
  SUBROUTINE MESH_TOPOLOGY_ELEMENTS_INITIALISE(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(MeshComponentTopologyType), POINTER :: TOPOLOGY !<A pointer to the mesh topology to initialise the elements for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("MESH_TOPOLOGY_ELEMENTS_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      IF(ASSOCIATED(TOPOLOGY%ELEMENTS)) THEN
        CALL FlagError("Mesh already has topology elements associated",ERR,ERROR,*999)
      ELSE
        ALLOCATE(TOPOLOGY%ELEMENTS,STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate topology elements",ERR,ERROR,*999)
        TOPOLOGY%ELEMENTS%NUMBER_OF_ELEMENTS=0
        TOPOLOGY%ELEMENTS%meshComponentTopology=>TOPOLOGY
        NULLIFY(TOPOLOGY%ELEMENTS%ELEMENTS)
        NULLIFY(TOPOLOGY%ELEMENTS%ELEMENTS_TREE)
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("MESH_TOPOLOGY_ELEMENTS_INITIALISE")
    RETURN
999 ERRORSEXITS("MESH_TOPOLOGY_ELEMENTS_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE MESH_TOPOLOGY_ELEMENTS_INITIALISE

  !
  !================================================================================================================================
  !

  !>Initialises the elements in a given mesh topology. \todo finalise on error
  SUBROUTINE MESH_TOPOLOGY_DATA_POINTS_INITIALISE(TOPOLOGY,ERR,ERROR,*)

    !Argument variables
    TYPE(MeshComponentTopologyType), POINTER :: TOPOLOGY !<A pointer to the mesh topology to initialise the elements for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("MESH_TOPOLOGY_DATA_POINTS_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(TOPOLOGY)) THEN
      IF(ASSOCIATED(TOPOLOGY%dataPoints)) THEN
        CALL FlagError("Mesh already has topology data points associated",ERR,ERROR,*999)
      ELSE
        ALLOCATE(TOPOLOGY%dataPoints,STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate topology data points",ERR,ERROR,*999)
        TOPOLOGY%dataPoints%totalNumberOfProjectedData=0
        TOPOLOGY%dataPoints%meshComponentTopology=>topology
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("MESH_TOPOLOGY_DATA_POINTS_INITIALISE")
    RETURN
999 ERRORSEXITS("MESH_TOPOLOGY_DATA_POINTS_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE MESH_TOPOLOGY_DATA_POINTS_INITIALISE

  !
  !================================================================================================================================
  !

!!MERGE: ditto.

  !>Gets the user number for a global element identified by a given global number. \todo Check that the user number doesn't already exist. \see OPENCMISS::Iron::cmfe_MeshElementsUserNumberGet
  SUBROUTINE MESH_TOPOLOGY_ELEMENTS_NUMBER_GET(GLOBAL_NUMBER,USER_NUMBER,ELEMENTS,ERR,ERROR,*)

    !Argument variables
    INTEGER(INTG), INTENT(IN) :: GLOBAL_NUMBER !<The global number of the elements to get.
    INTEGER(INTG), INTENT(OUT) :: USER_NUMBER !<The user number of the element to get
    TYPE(MeshElementsType), POINTER :: ELEMENTS !<On return, a pointer to the elements to get the user number for \todo This should be the first parameter.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("MESH_TOPOLOGY_ELEMENTS_NUMBER_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(ELEMENTS)) THEN
      IF(ELEMENTS%ELEMENTS_FINISHED) THEN
        CALL FlagError("Elements have been finished",ERR,ERROR,*999)
      ELSE
        IF(GLOBAL_NUMBER>=1.AND.GLOBAL_NUMBER<=ELEMENTS%NUMBER_OF_ELEMENTS) THEN
          USER_NUMBER=ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%USER_NUMBER
        ELSE
          LOCAL_ERROR="Global element number "//TRIM(NUMBER_TO_VSTRING(GLOBAL_NUMBER,"*",ERR,ERROR))// &
            & " is invalid. The limits are 1 to "//TRIM(NUMBER_TO_VSTRING(ELEMENTS%NUMBER_OF_ELEMENTS,"*",ERR,ERROR))
          CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Elements is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("MESH_TOPOLOGY_ELEMENTS_NUMBER_GET")
    RETURN
999 ERRORSEXITS("MESH_TOPOLOGY_ELEMENTS_NUMBER_GET",ERR,ERROR)
    RETURN 1

  END SUBROUTINE MESH_TOPOLOGY_ELEMENTS_NUMBER_GET

  !
  !================================================================================================================================
  !

  !>Returns the user number for a global element identified by a given global number. \see OPENCMISS::Iron::cmfe_MeshElementsUserNumberGet
  SUBROUTINE MeshElements_ElementUserNumberGet(GLOBAL_NUMBER,USER_NUMBER,ELEMENTS,ERR,ERROR,*)

    !Argument variables
    INTEGER(INTG), INTENT(IN) :: GLOBAL_NUMBER !<The global number of the elements to get.
    INTEGER(INTG), INTENT(OUT) :: USER_NUMBER !<The user number of the element to get
    TYPE(MeshElementsType), POINTER :: ELEMENTS !<A pointer to the elements to set the user number for \todo This should be the first parameter.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("MeshElements_ElementUserNumberGet",ERR,ERROR,*999)

    IF(ASSOCIATED(ELEMENTS)) THEN
      IF(ELEMENTS%ELEMENTS_FINISHED) THEN
        IF(GLOBAL_NUMBER>=1.AND.GLOBAL_NUMBER<=ELEMENTS%NUMBER_OF_ELEMENTS) THEN
          USER_NUMBER=ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%USER_NUMBER
        ELSE
          LOCAL_ERROR="Global element number "//TRIM(NUMBER_TO_VSTRING(GLOBAL_NUMBER,"*",ERR,ERROR))// &
            & " is invalid. The limits are 1 to "//TRIM(NUMBER_TO_VSTRING(ELEMENTS%NUMBER_OF_ELEMENTS,"*",ERR,ERROR))//"."
          CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Elements have not been finished.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Elements is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("MeshElements_ElementUserNumberGet")
    RETURN
999 ERRORSEXITS("MeshElements_ElementUserNumberGet",ERR,ERROR)
    RETURN 1


  END SUBROUTINE MeshElements_ElementUserNumberGet

  !
  !================================================================================================================================
  !

  !>Changes/sets the user number for a global element identified by a given global number. \see OPENCMISS::Iron::cmfe_MeshElementsUserNumberSet
  SUBROUTINE MeshElements_ElementUserNumberSet(GLOBAL_NUMBER,USER_NUMBER,ELEMENTS,ERR,ERROR,*)

    !Argument variables
    INTEGER(INTG), INTENT(IN) :: GLOBAL_NUMBER !<The global number of the elements to set.
    INTEGER(INTG), INTENT(IN) :: USER_NUMBER !<The user number of the element to set
    TYPE(MeshElementsType), POINTER :: ELEMENTS !<A pointer to the elements to set the user number for \todo This should be the first parameter.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code

    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: GLOBAL_ELEMENT_NUMBER,INSERT_STATUS
    TYPE(TREE_NODE_TYPE), POINTER :: TREE_NODE
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("MeshElements_ElementUserNumberSet",ERR,ERROR,*999)

    IF(ASSOCIATED(ELEMENTS)) THEN
      IF(ELEMENTS%ELEMENTS_FINISHED) THEN
        CALL FlagError("Elements have been finished.",ERR,ERROR,*999)
      ELSE
        IF(GLOBAL_NUMBER>=1.AND.GLOBAL_NUMBER<=ELEMENTS%NUMBER_OF_ELEMENTS) THEN
          NULLIFY(TREE_NODE)
          CALL TREE_SEARCH(ELEMENTS%ELEMENTS_TREE,USER_NUMBER,TREE_NODE,ERR,ERROR,*999)
          IF(ASSOCIATED(TREE_NODE)) THEN
            CALL TREE_NODE_VALUE_GET(ELEMENTS%ELEMENTS_TREE,TREE_NODE,GLOBAL_ELEMENT_NUMBER,ERR,ERROR,*999)
            LOCAL_ERROR="Element user number "//TRIM(NUMBER_TO_VSTRING(USER_NUMBER,"*",ERR,ERROR))// &
              & " is already used by global element number "// &
              & TRIM(NUMBER_TO_VSTRING(GLOBAL_ELEMENT_NUMBER,"*",ERR,ERROR))//"."
            CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
          ELSE
            CALL TREE_ITEM_DELETE(ELEMENTS%ELEMENTS_TREE,ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%USER_NUMBER,ERR,ERROR,*999)
            CALL TREE_ITEM_INSERT(ELEMENTS%ELEMENTS_TREE,USER_NUMBER,GLOBAL_NUMBER,INSERT_STATUS,ERR,ERROR,*999)
            ELEMENTS%ELEMENTS(GLOBAL_NUMBER)%USER_NUMBER=USER_NUMBER
          ENDIF
        ELSE
          LOCAL_ERROR="Global element number "//TRIM(NUMBER_TO_VSTRING(GLOBAL_NUMBER,"*",ERR,ERROR))// &
            & " is invalid. The limits are 1 to "//TRIM(NUMBER_TO_VSTRING(ELEMENTS%NUMBER_OF_ELEMENTS,"*",ERR,ERROR))//"."
          CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Elements is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("MeshElements_ElementUserNumberSet")
    RETURN
999 ERRORSEXITS("MeshElements_ElementUserNumberSet",ERR,ERROR)
    RETURN 1

  END SUBROUTINE MeshElements_ElementUserNumberSet

  !
  !================================================================================================================================
  !

  !>Changes/sets the user numbers for all elements.
  SUBROUTINE MeshTopology_ElementsUserNumbersAllSet(elements,userNumbers,err,error,*)

    !Argument variables
    TYPE(MeshElementsType), POINTER :: elements !<A pointer to the elements to set all the user numbers for
    INTEGER(INTG), INTENT(IN) :: userNumbers(:) !<The user numbers to set
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: elementIdx,insertStatus
    TYPE(TREE_TYPE), POINTER :: newElementsTree
    TYPE(VARYING_STRING) :: localError

    NULLIFY(newElementsTree)

    ENTERS("MeshTopology_ElementsUserNumbersAllSet",err,error,*999)

    IF(ASSOCIATED(elements)) THEN
      IF(elements%ELEMENTS_FINISHED) THEN
        CALL FlagError("Elements have been finished.",err,error,*999)
      ELSE
        IF(elements%NUMBER_OF_ELEMENTS==SIZE(userNumbers,1)) THEN
          !Check the users numbers to ensure that there are no duplicates
          CALL TREE_CREATE_START(newElementsTree,err,error,*999)
          CALL TREE_INSERT_TYPE_SET(newElementsTree,TREE_NO_DUPLICATES_ALLOWED,err,error,*999)
          CALL TREE_CREATE_FINISH(newElementsTree,err,error,*999)
          DO elementIdx=1,elements%NUMBER_OF_ELEMENTS
            CALL TREE_ITEM_INSERT(newElementsTree,userNumbers(elementIdx),elementIdx,insertStatus,err,error,*999)
            IF(insertStatus/=TREE_NODE_INSERT_SUCESSFUL) THEN
              localError="The specified user number of "//TRIM(NumberToVstring(userNumbers(elementIdx),"*",err,error))// &
                & " for global element number "//TRIM(NUMBER_TO_VSTRING(elementIdx,"*",err,error))// &
                & " is a duplicate. The user element numbers must be unique."
              CALL FlagError(localError,err,error,*999)
            ENDIF
          ENDDO !elementIdx
          CALL TREE_DESTROY(elements%ELEMENTS_TREE,err,error,*999)
          elements%ELEMENTS_TREE=>newElementsTree
          NULLIFY(newElementsTree)
          DO elementIdx=1,elements%NUMBER_OF_ELEMENTS
            elements%ELEMENTS(elementIdx)%GLOBAL_NUMBER=elementIdx
            elements%ELEMENTS(elementIdx)%USER_NUMBER=userNumbers(elementIdx)
          ENDDO !elementIdx
        ELSE
          localError="The number of specified element user numbers ("// &
            TRIM(NumberToVstring(SIZE(userNumbers,1),"*",err,error))// &
            ") does not match number of elements ("// &
            TRIM(NumberToVstring(elements%NUMBER_OF_ELEMENTS,"*",err,error))//")."
          CALL FlagError(localError,err,error,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Elements is not associated.",err,error,*999)
    ENDIF

    EXITS("MeshTopology_ElementsUserNumbersAllSet")
    RETURN
999 IF(ASSOCIATED(newElementsTree)) CALL TREE_DESTROY(newElementsTree,err,error,*998)
998 ERRORSEXITS("MeshTopology_ElementsUserNumbersAllSet",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_ElementsUserNumbersAllSet

  !
  !================================================================================================================================
  !

  !>Calculates the data points in the given mesh topology.
  SUBROUTINE MeshTopology_DataPointsCalculateProjection(mesh,dataProjection,err,error,*)

    !Argument variables
    TYPE(MESH_TYPE), POINTER :: mesh !<A pointer to the mesh topology to calcualte the data projection for
    TYPE(DataProjectionType), POINTER :: dataProjection !<A pointer to the data projection
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(DataPointsType), POINTER :: dataPoints !<A pointer to the data points
    TYPE(MeshDataPointsType), POINTER :: dataPointsTopology
    TYPE(DataProjectionResultType), POINTER :: dataProjectionResult
    TYPE(MeshElementsType), POINTER :: elements
    INTEGER(INTG) :: dataPointIdx,elementIdx,exitTag,countIdx,projectionNumber,globalCountIdx,elementNumber

    ENTERS("MeshTopology_DataPointsCalculateProjection",ERR,ERROR,*999)

    IF(ASSOCIATED(mesh)) THEN
      IF(dataProjection%dataProjectionFinished) THEN
        dataPoints=>dataProjection%dataPoints
        !Default the first mesh component topology to contain data points ! \TODO: need to be changed once the data points topology is moved under meshTopologyType.
        dataPointsTopology=>mesh%topology(1)%PTR%dataPoints
        !Extract the global number of the data projection
        projectionNumber=dataProjection%globalNumber
        !Hard code the first mesh component since element topology is the same for all mesh components
        !\TODO: need to be changed once the elements topology is moved under meshTopologyType.
        elements=>mesh%TOPOLOGY(1)%PTR%ELEMENTS
        ALLOCATE(dataPointsTopology%elementDataPoint(elements%NUMBER_OF_ELEMENTS),STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate data points topology element.",ERR,ERROR,*999)
        DO elementIdx=1,elements%NUMBER_OF_ELEMENTS
          dataPointsTopology%elementDataPoint(elementIdx)%elementNumber=elements%ELEMENTS(elementIdx)%GLOBAL_NUMBER
          dataPointsTopology%elementDataPoint(elementIdx)%numberOfProjectedData=0
        ENDDO
        !Calculate number of projected data points on an element
        DO dataPointIdx=1,dataPoints%numberOfDataPoints
          dataProjectionResult=>dataProjection%dataProjectionResults(dataPointIdx)
          elementNumber=dataProjectionResult%elementNumber
          exitTag=dataProjectionResult%exitTag
          IF(exitTag/=DATA_PROJECTION_CANCELLED) THEN
            DO elementIdx=1,elements%NUMBER_OF_ELEMENTS
              IF(dataPointsTopology%elementDataPoint(elementIdx)%elementNumber==elementNumber) THEN
                dataPointsTopology%elementDataPoint(elementIdx)%numberOfProjectedData= &
                  & dataPointsTopology%elementDataPoint(elementIdx)%numberOfProjectedData+1;
              ENDIF
            ENDDO !elementIdx
          ENDIF
        ENDDO !dataPointIdx
        !Allocate memory to store data indices and initialise them to be zero
        DO elementIdx=1,elements%NUMBER_OF_ELEMENTS
          ALLOCATE(dataPointsTopology%elementDataPoint(elementIdx)%dataIndices(dataPointsTopology% &
            & elementDataPoint(elementIdx)%numberOfProjectedData),STAT=ERR)
          IF(ERR/=0) CALL FlagError("Could not allocate data points topology element data points.",ERR,ERROR,*999)
          DO countIdx=1,dataPointsTopology%elementDataPoint(elementIdx)%numberOfProjectedData
            dataPointsTopology%elementDataPoint(elementIdx)%dataIndices(countIdx)%userNumber=0
            dataPointsTopology%elementDataPoint(elementIdx)%dataIndices(countIdx)%globalNumber=0
          ENDDO
        ENDDO
        !Record the indices of the data that projected on the elements
        globalCountIdx=0
        dataPointsTopology%totalNumberOfProjectedData=0
        DO dataPointIdx=1,dataPoints%numberOfDataPoints
          dataProjectionResult=>dataProjection%dataProjectionResults(dataPointIdx)
          elementNumber=dataProjectionResult%elementNumber
          exitTag=dataProjectionResult%exitTag
          IF(exitTag/=DATA_PROJECTION_CANCELLED) THEN
            DO elementIdx=1,elements%NUMBER_OF_ELEMENTS
              countIdx=1
              IF(dataPointsTopology%elementDataPoint(elementIdx)%elementNumber==elementNumber) THEN
                globalCountIdx=globalCountIdx+1
                !Find the next data point index in this element
                DO WHILE(dataPointsTopology%elementDataPoint(elementIdx)%dataIndices(countIdx)%globalNumber/=0)
                  countIdx=countIdx+1
                ENDDO
                dataPointsTopology%elementDataPoint(elementIdx)%dataIndices(countIdx)%userNumber=dataPointIdx
                dataPointsTopology%elementDataPoint(elementIdx)%dataIndices(countIdx)%globalNumber=dataPointIdx!globalCountIdx (used this if only projected data are taken into account)
                dataPointsTopology%totalNumberOfProjectedData=dataPointsTopology%totalNumberOfProjectedData+1
              ENDIF
            ENDDO !elementIdx
          ENDIF
        ENDDO !dataPointIdx
        !Allocate memory to store total data indices in ascending order and element map
        ALLOCATE(dataPointsTopology%dataPoints(dataPointsTopology%totalNumberOfProjectedData),STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate data points topology data points.",ERR,ERROR,*999)
        !The global number for the data points will be looping through elements.
        countIdx=1
        DO elementIdx=1,elements%NUMBER_OF_ELEMENTS
          DO dataPointIdx=1,dataPointsTopology%elementDataPoint(elementIdx)%numberOfProjectedData
            dataPointsTopology%dataPoints(countIdx)%userNumber=dataPointsTopology%elementDataPoint(elementIdx)% &
              & dataIndices(dataPointIdx)%userNumber
             dataPointsTopology%dataPoints(countIdx)%globalNumber=dataPointsTopology%elementDataPoint(elementIdx)% &
              & dataIndices(dataPointIdx)%globalNumber
             dataPointsTopology%dataPoints(countIdx)%elementNumber=dataPointsTopology%elementDataPoint(elementIdx)% &
               & elementNumber
             countIdx=countIdx+1
          ENDDO !dataPointIdx
        ENDDO !elementIdx
      ELSE
        CALL FlagError("Data projection is not finished.",err,error,*999)
      ENDIF
    ELSE
      CALL FlagError("Mesh is not associated.",err,error,*999)
    ENDIF

    EXITS("MeshTopology_DataPointsCalculateProjection")
    RETURN
999 ERRORSEXITS("MeshTopology_DataPointsCalculateProjection",err,error)
    RETURN 1
  END SUBROUTINE MeshTopology_DataPointsCalculateProjection

  !
  !================================================================================================================================
  !

  !>Finalises the topology in the given mesh. \todo pass in the mesh topology
  SUBROUTINE MeshTopology_Finalise(mesh,err,error,*)

    !Argument variables
    TYPE(MESH_TYPE), POINTER :: mesh !<A pointer to the mesh to finalise the topology for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: componentIdx

    ENTERS("MeshTopology_Finalise",err,error,*999)

    IF(ASSOCIATED(mesh)) THEN
      DO componentIdx=1,mesh%NUMBER_OF_COMPONENTS
        CALL MeshTopology_ComponentFinalise(mesh%topology(componentIdx)%ptr,err,error,*999)
      ENDDO !componentIdx
      DEALLOCATE(mesh%topology)
    ELSE
      CALL FlagError("Mesh is not associated.",err,error,*999)
    ENDIF

    EXITS("MeshTopology_Finalise")
    RETURN
999 ERRORSEXITS("MeshTopology_Finalise",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_Finalise

  !
  !================================================================================================================================
  !

  !>Finalises the topology in the given mesh.
  SUBROUTINE MeshTopology_ComponentFinalise(meshComponent,err,error,*)

    !Argument variables
    TYPE(MeshComponentTopologyType), POINTER :: meshComponent !<A pointer to the mesh component to finalise the topology for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables

    ENTERS("MeshTopology_ComponentFinalise",err,error,*999)

    IF(ASSOCIATED(meshComponent)) THEN
      CALL MeshTopology_NodesFinalise(meshComponent%nodes,err,error,*999)
      CALL MESH_TOPOLOGY_ELEMENTS_FINALISE(meshComponent%elements,err,error,*999)
      CALL MeshTopology_DofsFinalise(meshComponent%dofs,err,error,*999)
      DEALLOCATE(meshComponent)
    ENDIF

    EXITS("MeshTopology_ComponentFinalise")
    RETURN
999 ERRORSEXITS("MeshTopology_ComponentFinalise",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_ComponentFinalise

  !
  !================================================================================================================================
  !

  !>Initialises the topology for a given mesh. \todo finalise on error
  SUBROUTINE MeshTopology_Initialise(mesh,err,error,*)

    !Argument variables
    TYPE(MESH_TYPE), POINTER :: mesh !<A pointer to the mesh to initialise the mesh topology for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: componentIdx

    ENTERS("MeshTopology_Initialise",err,error,*999)

    IF(ASSOCIATED(mesh)) THEN
      IF(ASSOCIATED(mesh%topology)) THEN
        CALL FlagError("Mesh already has topology associated.",err,error,*999)
      ELSE
        !Allocate mesh topology
        ALLOCATE(mesh%topology(mesh%NUMBER_OF_COMPONENTS),STAT=err)
        IF(err/=0) CALL FlagError("Mesh topology could not be allocated.",err,error,*999)
        DO componentIdx=1,mesh%NUMBER_OF_COMPONENTS
          ALLOCATE(mesh%topology(componentIdx)%ptr,STAT=err)
          IF(err/=0) CALL FlagError("Mesh topology component could not be allocated.",err,error,*999)
          mesh%topology(componentIdx)%ptr%mesh=>mesh
          NULLIFY(mesh%topology(componentIdx)%ptr%elements)
          NULLIFY(mesh%topology(componentIdx)%ptr%nodes)
          NULLIFY(mesh%topology(componentIdx)%ptr%dofs)
          NULLIFY(mesh%topology(componentIdx)%ptr%dataPoints)
          !Initialise the topology components
          CALL MESH_TOPOLOGY_ELEMENTS_INITIALISE(mesh%topology(componentIdx)%ptr,err,error,*999)
          CALL MeshTopology_NodesInitialise(mesh%topology(componentIdx)%ptr,err,error,*999)
          CALL MeshTopology_DofsInitialise(mesh%topology(componentIdx)%ptr,err,error,*999)
          CALL MESH_TOPOLOGY_DATA_POINTS_INITIALISE(mesh%topology(componentIdx)%ptr,err,error,*999)
        ENDDO !componentIdx
      ENDIF
    ELSE
      CALL FlagError("Mesh is not associated.",err,error,*999)
    ENDIF

    EXITS("MeshTopology_Initialise")
    RETURN
999 ERRORSEXITS("MeshTopology_Initialise",err,error)
    RETURN 1
  END SUBROUTINE MeshTopology_Initialise

  !
  !================================================================================================================================
  !

  !>Checks that a user element number exists in a mesh component.
  SUBROUTINE MeshTopology_ElementCheckExistsMesh(mesh,meshComponentNumber,userElementNumber,elementExists,globalElementNumber, &
    & err,error,*)

    !Argument variables
    TYPE(MESH_TYPE), POINTER :: mesh !<A pointer to the mesh to check the element exists on
    INTEGER(INTG), INTENT(IN) :: meshComponentNumber !<The mesh component to check the element exits on
    INTEGER(INTG), INTENT(IN) :: userElementNumber !<The user element number to check if it exists
    LOGICAL, INTENT(OUT) :: elementExists !<On exit, is .TRUE. if the element user number exists in the mesh component, .FALSE. if not
    INTEGER(INTG), INTENT(OUT) :: globalElementNumber !<On exit, if the element exists the global number corresponding to the user element number. If the element does not exist then global number will be 0.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    TYPE(MeshElementsType), POINTER :: elements

    NULLIFY(elements)

    ENTERS("MeshTopology_ElementCheckExistsMesh",err,error,*999)

    IF(ASSOCIATED(mesh)) THEN
      IF(mesh%MESH_FINISHED) THEN
        CALL MESH_TOPOLOGY_ELEMENTS_GET(mesh,meshComponentNumber,elements,err,error,*999)
        CALL MeshTopology_ElementCheckExistsMeshElements(elements,userElementNumber,elementExists,globalElementNumber, &
          & err,error,*999)
      ELSE
        CALL FlagError("Mesh has not been finished.",err,error,*999)
      ENDIF
    ELSE
      CALL FlagError("Mesh is not associated.",err,error,*999)
    ENDIF

    EXITS("MeshTopology_ElementCheckExistsMesh")
    RETURN
999 ERRORSEXITS("MeshTopology_ElementCheckExistsMesh",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_ElementCheckExistsMesh

  !
  !================================================================================================================================
  !

  !>Checks that a user element number exists in a mesh elements.
  SUBROUTINE MeshTopology_ElementCheckExistsMeshElements(meshElements,userElementNumber,elementExists,globalElementNumber, &
    & err,error,*)

    !Argument variables
    TYPE(MeshElementsType), POINTER :: meshElements !<A pointer to the mesh elements to check the element exists on
    INTEGER(INTG), INTENT(IN) :: userElementNumber !<The user element number to check if it exists
    LOGICAL, INTENT(OUT) :: elementExists !<On exit, is .TRUE. if the element user number exists in the mesh elements, .FALSE. if not
    INTEGER(INTG), INTENT(OUT) :: globalElementNumber !<On exit, if the element exists the global number corresponding to the user element number. If the element does not exist then global number will be 0.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    TYPE(TREE_NODE_TYPE), POINTER :: treeNode

    ENTERS("MeshTopology_ElementCheckExistsMeshElements",err,error,*999)

    elementExists=.FALSE.
    globalElementNumber=0
    IF(ASSOCIATED(meshElements)) THEN
      NULLIFY(treeNode)
      CALL TREE_SEARCH(meshElements%ELEMENTS_TREE,userElementNumber,treeNode,err,error,*999)
      IF(ASSOCIATED(treeNode)) THEN
        CALL TREE_NODE_VALUE_GET(meshElements%ELEMENTS_TREE,treeNode,globalElementNumber,err,error,*999)
        elementExists=.TRUE.
      ENDIF
    ELSE
      CALL FlagError("Mesh elements is not associated.",err,error,*999)
    ENDIF

    EXITS("MeshTopology_ElementCheckExistsMeshElements")
    RETURN
999 ERRORSEXITS("MeshTopology_ElementCheckExistsMeshElements",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_ElementCheckExistsMeshElements

  !
  !================================================================================================================================
  !

  !>Gets a mesh element number that corresponds to a user element number from mesh element. An error will be raised if the user element number does not exist.
  SUBROUTINE MeshTopology_ElementGetMeshElements(meshElements,userElementNumber,globalElementNumber,err,error,*)

    !Argument variables
    TYPE(MeshElementsType), POINTER :: meshElements !<A pointer to the mesh elements to get the element for
    INTEGER(INTG), INTENT(IN) :: userElementNumber !<The user element number to get
    INTEGER(INTG), INTENT(OUT) :: globalElementNumber !<On exit, the global number corresponding to the user element number.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    LOGICAL :: elementExists
    TYPE(MESH_TYPE), POINTER :: mesh
    TYPE(MeshComponentTopologyType), POINTER :: meshComponentTopology
    TYPE(VARYING_STRING) :: localError

    ENTERS("MeshTopology_ElementGetMeshElements",err,error,*999)

    CALL MeshTopology_ElementCheckExistsMeshElements(meshElements,userElementNumber,elementExists,globalElementNumber, &
      & err,error,*999)
    IF(.NOT.elementExists) THEN
      meshComponentTopology=>meshElements%meshComponentTopology
      IF(ASSOCIATED(meshComponentTopology)) THEN
        mesh=>meshComponentTopology%mesh
        IF(ASSOCIATED(mesh)) THEN
          localError="The user element number "//TRIM(NumberToVString(userElementNumber,"*",err,error))// &
            & " does not exist in mesh number "//TRIM(NumberToVString(mesh%USER_NUMBER,"*",err,error))//"."
          CALL FlagError(localError,err,error,*999)
        ELSE
          localError="The user element number "//TRIM(NumberToVString(userElementNumber,"*",err,error))//" does not exist."
          CALL FlagError(localError,err,error,*999)
        ENDIF
      ELSE
        localError="The user element number "//TRIM(NumberToVString(userElementNumber,"*",err,error))//" does not exist."
        CALL FlagError(localError,err,error,*999)
      ENDIF
    ENDIF

    EXITS("MeshTopology_ElementGetMeshElements")
    RETURN
999 globalElementNumber=0
    ERRORSEXITS("MeshTopology_ElementGetMeshElements",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_ElementGetMeshElements

  !
  !================================================================================================================================
  !

  !>Returns if the element in a mesh is on the boundary or not
  SUBROUTINE MeshTopology_ElementOnBoundaryGet(meshElements,userNumber,onBoundary,err,error,*)

    !Argument variables
    TYPE(MeshElementsType), POINTER :: meshElements !<A pointer to the mesh element containing the element to get the boundary type for
    INTEGER(INTG), INTENT(IN) :: userNumber !<The user element number to get the boundary type for
    INTEGER(INTG), INTENT(OUT) :: onBoundary !<On return, the boundary type of the specified user element number.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: globalNumber

    ENTERS("MeshTopology_ElementOnBoundaryGet",err,error,*999)

    IF(.NOT.ASSOCIATED(meshElements)) CALL FlagError("Mesh elements is not associated.",err,error,*999)
    IF(.NOT.ASSOCIATED(meshElements%elements)) CALL FlagError("Mesh elements elements is not associated.",err,error,*999)

    CALL MeshTopology_ElementGet(meshElements,userNumber,globalNumber,err,error,*999)
    IF(meshElements%elements(globalNumber)%boundary_Element) THEN
      onBoundary=MESH_ON_DOMAIN_BOUNDARY
    ELSE
      onBoundary=MESH_OFF_DOMAIN_BOUNDARY
    ENDIF

    EXITS("MeshTopology_ElementOnBoundaryGet")
    RETURN
999 onBoundary=MESH_OFF_DOMAIN_BOUNDARY
    ERRORSEXITS("MeshTopology_ElementOnBoundaryGet",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_ElementOnBoundaryGet

  !
  !================================================================================================================================
  !

  !>Checks that a user node number exists in a mesh component.
  SUBROUTINE MeshTopology_NodeCheckExistsMesh(mesh,meshComponentNumber,userNodeNumber,nodeExists,meshNodeNumber,err,error,*)

    !Argument variables
    TYPE(MESH_TYPE), POINTER :: mesh !<A pointer to the mesh to check the node exists on
    INTEGER(INTG), INTENT(IN) :: meshComponentNumber !<The mesh component to check the node exits on
    INTEGER(INTG), INTENT(IN) :: userNodeNumber !<The user node number to check if it exists
    LOGICAL, INTENT(OUT) :: nodeExists !<On exit, is .TRUE. if the node user number exists in the mesh component, .FALSE. if not
    INTEGER(INTG), INTENT(OUT) :: meshNodeNumber !<On exit, if the node exists the mesh number corresponding to the user node number. If the node does not exist then mesh number will be 0.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: globalNodeNumber
    TYPE(MeshNodesType), POINTER :: meshNodes
    TYPE(NODES_TYPE), POINTER :: nodes
    TYPE(REGION_TYPE), POINTER :: region
    TYPE(TREE_NODE_TYPE), POINTER :: treeNode

    NULLIFY(meshNodes)
    NULLIFY(nodes)
    NULLIFY(region)

    ENTERS("MeshTopology_NodeCheckExistsMesh",err,error,*999)

    nodeExists=.FALSE.
    meshNodeNumber=0
    IF(ASSOCIATED(mesh)) THEN
      IF(mesh%MESH_FINISHED) THEN
        CALL MeshTopology_NodesGet(mesh,meshComponentNumber,meshNodes,err,error,*999)
        CALL Mesh_RegionGet(mesh,region,err,error,*999)
        nodes=>region%nodes
        IF(ASSOCIATED(nodes)) THEN
          CALL NODE_CHECK_EXISTS(nodes,userNodeNumber,nodeExists,globalNodeNumber,err,error,*999)
          NULLIFY(treeNode)
          CALL TREE_SEARCH(meshNodes%nodesTree,globalNodeNumber,treeNode,err,error,*999)
          IF(ASSOCIATED(treeNode)) THEN
            CALL TREE_NODE_VALUE_GET(meshNodes%nodesTree,treeNode,meshNodeNumber,err,error,*999)
            nodeExists=.TRUE.
          ENDIF
        ELSE
          CALL FlagError("Region nodes is not associated.",err,error,*999)
        ENDIF
      ELSE
        CALL FlagError("Mesh has not been finished.",err,error,*999)
      ENDIF
    ELSE
      CALL FlagError("Mesh is not associated.",err,error,*999)
    ENDIF

    EXITS("MeshTopology_NodeCheckExistsMesh")
    RETURN
999 ERRORSEXITS("MeshTopology_NodeCheckExistsMesh",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_NodeCheckExistsMesh

  !
  !================================================================================================================================
  !

  !>Checks that a user node number exists in a mesh nodes.
  SUBROUTINE MeshTopology_NodeCheckExistsMeshNodes(meshNodes,userNodeNumber,nodeExists,meshNodeNumber,err,error,*)

    !Argument variables
    TYPE(MeshNodesType), POINTER :: meshNodes !<A pointer to the mesh nodes to check the node exists on
    INTEGER(INTG), INTENT(IN) :: userNodeNumber !<The user node number to check if it exists
    LOGICAL, INTENT(OUT) :: nodeExists !<On exit, is .TRUE. if the node user number exists in the mesh nodes, .FALSE. if not
    INTEGER(INTG), INTENT(OUT) :: meshNodeNumber !<On exit, if the node exists the mesh number corresponding to the user node number. If the node does not exist then mesh number will be 0.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: globalNodeNumber
    TYPE(MESH_TYPE), POINTER :: mesh
    TYPE(MeshComponentTopologyType), POINTER :: meshComponentTopology
    TYPE(NODES_TYPE), POINTER :: nodes
    TYPE(REGION_TYPE), POINTER :: region
    TYPE(TREE_NODE_TYPE), POINTER :: treeNode

    NULLIFY(nodes)
    NULLIFY(region)

    ENTERS("MeshTopology_NodeCheckExistsMeshNodes",err,error,*999)

    nodeExists=.FALSE.
    meshNodeNumber=0
    IF(ASSOCIATED(meshNodes)) THEN
      meshComponentTopology=>meshNodes%meshComponentTopology
      IF(ASSOCIATED(meshComponentTopology)) THEN
        mesh=>meshComponentTopology%mesh
        IF(ASSOCIATED(mesh)) THEN
          IF(mesh%MESH_FINISHED) THEN
            CALL Mesh_RegionGet(mesh,region,err,error,*999)
            CALL Region_NodesGet(region,nodes,err,error,*999)
            CALL NODE_CHECK_EXISTS(nodes,userNodeNumber,nodeExists,globalNodeNumber,err,error,*999)
            NULLIFY(treeNode)
            CALL TREE_SEARCH(meshNodes%nodesTree,globalNodeNumber,treeNode,err,error,*999)
            IF(ASSOCIATED(treeNode)) THEN
              CALL TREE_NODE_VALUE_GET(meshNodes%nodesTree,treeNode,meshNodeNumber,err,error,*999)
              nodeExists=.TRUE.
            ENDIF
         ELSE
            CALL FlagError("Mesh has not been finished.",err,error,*999)
          ENDIF
        ELSE
          CALL FlagError("Mesh component topology mesh is not associated.",err,error,*999)
        ENDIF
      ELSE
        CALL FlagError("Mesh nodes mesh component topology is not associated.",err,error,*999)
      ENDIF
    ELSE
      CALL FlagError("Mesh nodes is not associated.",err,error,*999)
    ENDIF

    EXITS("MeshTopology_NodeCheckExistsMeshNodes")
    RETURN
999 ERRORSEXITS("MeshTopology_NodeCheckExistsMeshNodes",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_NodeCheckExistsMeshNodes

  !
  !================================================================================================================================
  !

  !>Gets a mesh node number that corresponds to a user node number from mesh nodes. An error will be raised if the user node number does not exist.
  SUBROUTINE MeshTopology_NodeGetMeshNodes(meshNodes,userNodeNumber,meshNodeNumber,err,error,*)

    !Argument variables
    TYPE(MeshNodesType), POINTER :: meshNodes !<A pointer to the mesh nodes to get the node from
    INTEGER(INTG), INTENT(IN) :: userNodeNumber !<The user node number to get
    INTEGER(INTG), INTENT(OUT) :: meshNodeNumber !<On exit, the mesh number corresponding to the user node number.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: meshComponentNumber
    LOGICAL :: nodeExists
    TYPE(MESH_TYPE), POINTER :: mesh
    TYPE(MeshComponentTopologyType), POINTER :: meshComponentTopology
    TYPE(VARYING_STRING) :: localError

    ENTERS("MeshTopology_NodeGetMeshNodes",err,error,*999)

    CALL MeshTopology_NodeCheckExistsMeshNodes(meshNodes,userNodeNumber,nodeExists,meshNodeNumber,err,error,*999)
    IF(.NOT.nodeExists) THEN
      meshComponentTopology=>meshNodes%meshComponentTopology
      IF(ASSOCIATED(meshComponentTopology)) THEN
        mesh=>meshComponentTopology%mesh
        IF(ASSOCIATED(mesh)) THEN
          meshComponentNumber=meshComponentTopology%meshComponentNumber
          localError="The user node number "//TRIM(NumberToVString(userNodeNumber,"*",err,error))// &
            & " does not exist in mesh component number "//TRIM(NumberToVString(meshComponentNumber,"*",err,error))// &
            & " of mesh number "//TRIM(NumberToVString(mesh%USER_NUMBER,"*",err,error))//"."
          CALL FlagError(localError,err,error,*999)
        ELSE
          localError="The user node number "//TRIM(NumberToVString(userNodeNumber,"*",err,error))// &
            & " does not exist in mesh component number "//TRIM(NumberToVString(meshComponentNumber,"*",err,error))//"."
          CALL FlagError(localError,err,error,*999)
        ENDIF
      ELSE
        localError="The user node number "//TRIM(NumberToVString(userNodeNumber,"*",err,error))//" does not exist."
        CALL FlagError(localError,err,error,*999)
      ENDIF
    ENDIF

    EXITS("MeshTopology_NodeGetMeshNodes")
    RETURN
999 meshNodeNumber=0
    ERRORSEXITS("MeshTopology_NodeGetMeshNodes",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_NodeGetMeshNodes

  !
  !================================================================================================================================
  !

  !>Finalises the given mesh topology node.
  SUBROUTINE MeshTopology_NodeFinalise(node,err,error,*)

    !Argument variables
    TYPE(MeshNodeType) :: node !<The mesh node to finalise
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: derivativeIdx

    ENTERS("MeshTopology_NodeFinalise",err,error,*999)

    IF(ALLOCATED(node%derivatives)) THEN
      DO derivativeIdx=1,node%numberOfDerivatives
        CALL MeshTopology_NodeDerivativeFinalise(node%derivatives(derivativeIdx),err,error,*999)
      ENDDO !derivativeIdx
      DEALLOCATE(node%derivatives)
    ENDIF
    IF(ASSOCIATED(node%surroundingElements)) DEALLOCATE(node%surroundingElements)

    EXITS("MeshTopology_NodeFinalise")
    RETURN
999 ERRORSEXITS("MeshTopology_NodeFinalise",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_NodeFinalise

  !
  !================================================================================================================================
  !

  !>Initialises the given mesh topology node.
  SUBROUTINE MeshTopology_NodeInitialise(node,err,error,*)

    !Argument variables
    TYPE(MeshNodeType) :: node !<The mesh node to initialise
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables

    ENTERS("MeshTopology_NodeInitialise",err,error,*999)

    node%userNumber=0
    node%globalNumber=0
    node%numberOfSurroundingElements=0
    NULLIFY(node%surroundingElements)
    node%numberOfDerivatives=0
    node%boundaryNode=.FALSE.

    EXITS("MeshTopology_NodeInitialise")
    RETURN
999 ERRORSEXITS("MeshTopology_NodeInitialise",err,error)
    RETURN 1
  END SUBROUTINE MeshTopology_NodeInitialise

  !
  !================================================================================================================================
  !

  !>Calculates the nodes used the mesh identified by a given mesh topology.
  SUBROUTINE MeshTopology_NodesCalculate(topology,err,error,*)

    !Argument variables
    TYPE(MeshComponentTopologyType), POINTER :: topology !<A pointer to the mesh topology
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: dummyErr,elementIdx,insertStatus,localNodeIdx,globalNode,meshNodeIdx,meshNode,numberOfNodes
    INTEGER(INTG), POINTER :: globalNodeNumbers(:)
    TYPE(BASIS_TYPE), POINTER :: basis
    TYPE(MESH_TYPE), POINTER :: mesh
    TYPE(MeshElementsType), POINTER :: elements
    TYPE(MeshNodesType), POINTER :: meshNodes
    TYPE(NODES_TYPE), POINTER :: nodes
    TYPE(TREE_TYPE), POINTER :: globalNodesTree
    TYPE(TREE_NODE_TYPE), POINTER :: treeNode
    TYPE(VARYING_STRING) :: dummyError,localError

    NULLIFY(globalNodeNumbers)
    NULLIFY(globalNodesTree)

    ENTERS("MeshTopology_NodesCalculate",err,error,*998)

    IF(ASSOCIATED(topology)) THEN
      elements=>topology%elements
      IF(ASSOCIATED(elements)) THEN
        meshNodes=>topology%nodes
        IF(ASSOCIATED(meshNodes)) THEN
          mesh=>topology%mesh
          IF(ASSOCIATED(mesh)) THEN
            NULLIFY(nodes)
            CALL MeshGlobalNodesGet(mesh,nodes,err,error,*999)
            IF(ALLOCATED(meshNodes%nodes)) THEN
              localError="Mesh number "//TRIM(NumberToVString(mesh%USER_NUMBER,"*",err,error))// &
                & " already has allocated mesh topology nodes."
              CALL FlagError(localError,err,error,*998)
            ELSE
              !Work out what nodes are in the mesh
              CALL TREE_CREATE_START(globalNodesTree,err,error,*999)
              CALL TREE_INSERT_TYPE_SET(globalNodesTree,TREE_NO_DUPLICATES_ALLOWED,err,error,*999)
              CALL TREE_CREATE_FINISH(globalNodesTree,err,error,*999)
              DO elementIdx=1,elements%NUMBER_OF_ELEMENTS
                basis=>elements%elements(elementIdx)%basis
                DO localNodeIdx=1,basis%NUMBER_OF_NODES
                  globalNode=elements%elements(elementIdx)%GLOBAL_ELEMENT_NODES(localNodeIdx)
                  CALL TREE_ITEM_INSERT(globalNodesTree,globalNode,globalNode,insertStatus,err,error,*999)
                ENDDO !localNodeIdx
              ENDDO !elementIdx
              CALL TREE_DETACH_AND_DESTROY(globalNodesTree,numberOfNodes,globalNodeNumbers,err,error,*999)
              !Set up the mesh nodes.
              ALLOCATE(meshNodes%nodes(numberOfNodes),STAT=err)
              IF(err/=0) CALL FlagError("Could not allocate mesh topology nodes nodes.",err,error,*999)
              CALL TREE_CREATE_START(meshNodes%nodesTree,err,error,*999)
              CALL TREE_INSERT_TYPE_SET(meshNodes%nodesTree,TREE_NO_DUPLICATES_ALLOWED,err,error,*999)
              CALL TREE_CREATE_FINISH(meshNodes%nodesTree,err,error,*999)
              DO meshNodeIdx=1,numberOfNodes
                CALL MeshTopology_NodeInitialise(meshNodes%nodes(meshNodeIdx),err,error,*999)
                meshNodes%nodes(meshNodeIdx)%meshNumber=meshNodeIdx
                meshNodes%nodes(meshNodeIdx)%globalNumber=globalNodeNumbers(meshNodeIdx)
                meshNodes%nodes(meshNodeIdx)%userNumber=nodes%nodes(globalNodeNumbers(meshNodeIdx))%USER_NUMBER
                CALL TREE_ITEM_INSERT(meshNodes%nodesTree,globalNodeNumbers(meshNodeIdx),meshNodeIdx,insertStatus,err,error,*999)
              ENDDO !nodeIdx
              meshNodes%numberOfNodes=numberOfNodes
              IF(ASSOCIATED(globalNodeNumbers)) DEALLOCATE(globalNodeNumbers)
              !Now recalculate the mesh element nodes
              DO elementIdx=1,elements%NUMBER_OF_ELEMENTS
                basis=>elements%elements(elementIdx)%basis
                ALLOCATE(elements%elements(elementIdx)%MESH_ELEMENT_NODES(basis%NUMBER_OF_NODES),STAT=err)
                IF(err/=0) CALL FlagError("Could not allocate mesh topology elements mesh element nodes.",err,error,*999)
                DO localNodeIdx=1,basis%NUMBER_OF_NODES
                  globalNode=elements%elements(elementIdx)%GLOBAL_ELEMENT_NODES(localNodeIdx)
                  NULLIFY(treeNode)
                  CALL TREE_SEARCH(meshNodes%nodesTree,globalNode,treeNode,err,error,*999)
                  IF(ASSOCIATED(treeNode)) THEN
                    CALL TREE_NODE_VALUE_GET(meshNodes%nodesTree,treeNode,meshNode,err,error,*999)
                    elements%elements(elementIdx)%MESH_ELEMENT_NODES(localNodeIdx)=meshNode
                  ELSE
                    localError="Could not find global node "//TRIM(NumberToVString(globalNode,"*",err,error))//" (user node "// &
                      & TRIM(NumberToVString(nodes%nodes(globalNode)%USER_NUMBER,"*",err,error))//") in the mesh nodes."
                    CALL FlagError(localError,err,error,*999)
                  ENDIF
                ENDDO !localNodeIdx
              ENDDO !elementIdx
            ENDIF
          ELSE
            CALL FlagError("Mesh topology mesh is not associated.",err,error,*998)
          ENDIF
        ELSE
          CALL FlagError("Mesh topology nodes is not associated.",err,error,*998)
        ENDIF
      ELSE
        CALL FlagError("Mesh topology elements is not associated.",err,error,*998)
      ENDIF
    ELSE
      CALL FlagError("Mesh topology is not associated.",err,error,*998)
    ENDIF

    IF(DIAGNOSTICS1) THEN
      CALL WriteStringValue(DIAGNOSTIC_OUTPUT_TYPE,"Number of mesh nodes = ",meshNodes%numberOfNodes,err,error,*999)
      DO meshNodeIdx=1,meshNodes%numberOfNodes
        CALL WriteStringValue(DIAGNOSTIC_OUTPUT_TYPE,"  Mesh node number = ",meshNodeIdx,err,error,*999)
        CALL WriteStringValue(DIAGNOSTIC_OUTPUT_TYPE,"    Global node number = ",meshNodes%nodes(meshNodeIdx)%globalNumber, &
          & err,error,*999)
      ENDDO !meshNodeIdx
    ENDIF

    EXITS("MeshTopology_NodesCalculate")
    RETURN
999 IF(ASSOCIATED(globalNodeNumbers)) DEALLOCATE(globalNodeNumbers)
    IF(ASSOCIATED(globalNodesTree)) CALL TREE_DESTROY(globalNodesTree,dummyErr,dummyError,*998)
998 ERRORSEXITS("MeshTopology_NodesCalculate",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_NodesCalculate

  !
  !================================================================================================================================
  !

  !>Destroys the nodes in a mesh topology.
  SUBROUTINE MeshTopology_NodesDestroy(nodes,err,error,*)

    !Argument variables
    TYPE(MeshNodesType), POINTER :: nodes !<A pointer to the mesh nodes to destroy
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables

    ENTERS("MeshTopology_NodesDestroy",err,error,*999)

    IF(ASSOCIATED(nodes)) THEN
      CALL MeshTopology_NodesFinalise(nodes,err,error,*999)
    ELSE
      CALL FlagError("Mesh topology nodes is not associated",err,error,*999)
    ENDIF

    EXITS("MeshTopology_NodesDestroy")
    RETURN
999 ERRORSEXITS("MeshTopology_NodesDestroy",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_NodesDestroy

  !
  !================================================================================================================================
  !

  !>Finalises the given mesh topology node.
  SUBROUTINE MeshTopology_NodeDerivativeFinalise(nodeDerivative,err,error,*)

    !Argument variables
    TYPE(MeshNodeDerivativeType) :: nodeDerivative !<The mesh node derivative to finalise
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables

    ENTERS("MeshTopology_NodeDerivativeFinalise",err,error,*999)

    IF(ALLOCATED(nodeDerivative%userVersionNumbers)) DEALLOCATE(nodeDerivative%userVersionNumbers)
    IF(ALLOCATED(nodeDerivative%dofIndex)) DEALLOCATE(nodeDerivative%dofIndex)

    EXITS("MeshTopology_NodeDerivativeFinalise")
    RETURN
999 ERRORSEXITS("MeshTopology_NodeDerivativeFinalise",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_NodeDerivativeFinalise

  !
  !================================================================================================================================
  !

  !>Initialises the given mesh topology node.
  SUBROUTINE MeshTopology_NodeDerivativeInitialise(nodeDerivative,err,error,*)

    !Argument variables
    TYPE(MeshNodeDerivativeType) :: nodeDerivative !<The mesh node derivative to initialise
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables

    ENTERS("MeshTopology_NodeDerivativeInitialise",err,error,*999)

    nodeDerivative%numberOfVersions=0
    nodeDerivative%globalDerivativeIndex=0
    nodederivative%partialDerivativeIndex=0

    EXITS("MeshTopology_NodeDerivativeInitialise")
    RETURN
999 ERRORSEXITS("MeshTopology_NodeDerivativeInitialise",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_NodeDerivativeInitialise

  !
  !================================================================================================================================
  !

  !>Calculates the number of derivatives at each node in a topology.
  SUBROUTINE MeshTopology_NodesDerivativesCalculate(topology,err,error,*)

    !Argument variables
    TYPE(MeshComponentTopologyType), POINTER :: topology !<A pointer to the mesh topology to calculate the derivates at each node for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: derivativeIdx,element,elementIdx,globalDerivative,localNodeIdx,maxNumberOfDerivatives,nodeIdx, &
      & numberOfDerivatives
    INTEGER(INTG), ALLOCATABLE :: derivatives(:)
    LOGICAL :: found
    TYPE(LIST_TYPE), POINTER :: nodeDerivativeList
    TYPE(MeshElementsType), POINTER :: elements
    TYPE(MeshNodesType), POINTER :: nodes
    TYPE(BASIS_TYPE), POINTER :: basis
    TYPE(VARYING_STRING) :: localError

    ENTERS("MeshTopology_NodesDerivativesCalculate",err,ERROR,*999)

     IF(ASSOCIATED(topology)) THEN
       elements=>topology%elements
       IF(ASSOCIATED(elements)) THEN
         nodes=>topology%nodes
         IF(ASSOCIATED(nodes)) THEN
          !Loop over the mesh nodes
          DO nodeIdx=1,nodes%numberOfNodes
            !Calculate the number of derivatives and versions at each node. This needs to be calculated by looking at the
            !mesh elements as we may have an adjacent element in another domain with a higher order basis also with versions.
            NULLIFY(nodeDerivativeList)
            CALL LIST_CREATE_START(nodeDerivativeList,err,error,*999)
            CALL LIST_DATA_TYPE_SET(nodeDerivativeList,LIST_INTG_TYPE,err,error,*999)
            CALL LIST_INITIAL_SIZE_SET(nodeDerivativeList,8,err,error,*999)
            CALL LIST_CREATE_FINISH(nodeDerivativeList,err,error,*999)
            maxNumberOfDerivatives=-1
            DO elementIdx=1,nodes%nodes(nodeIdx)%numberOfSurroundingElements
              element=nodes%nodes(nodeIdx)%surroundingElements(elementIdx)
              basis=>elements%elements(element)%basis
              !Find the local node corresponding to this node
              found=.FALSE.
              DO localNodeIdx=1,basis%NUMBER_OF_NODES
                IF(elements%elements(element)%MESH_ELEMENT_NODES(localNodeIdx)==nodeIdx) THEN
                  found=.TRUE.
                  EXIT
                ENDIF
              ENDDO !nn
              IF(found) THEN
                DO derivativeIdx=1,basis%NUMBER_OF_DERIVATIVES(localNodeIdx)
                  CALL LIST_ITEM_ADD(nodeDerivativeList,basis%PARTIAL_DERIVATIVE_INDEX(derivativeIdx,localNodeIdx),err,error,*999)
                ENDDO !derivativeIdx
                IF(basis%NUMBER_OF_DERIVATIVES(localNodeIdx)>maxNumberOfDerivatives) &
                  & maxNumberOfDerivatives=basis%NUMBER_OF_DERIVATIVES(localNodeidx)
              ELSE
                CALL FlagError("Could not find local node.",err,error,*999)
              ENDIF
            ENDDO !elem_idx
            CALL LIST_REMOVE_DUPLICATES(nodeDerivativeList,err,error,*999)
            CALL LIST_DETACH_AND_DESTROY(nodeDerivativeList,numberOfDerivatives,derivatives,err,error,*999)
            IF(numberOfDerivatives==maxNumberOfDerivatives) THEN
              !Set up the node derivatives.
              ALLOCATE(nodes%nodes(nodeIdx)%derivatives(maxNumberOfDerivatives),STAT=err)
              nodes%nodes(nodeIdx)%numberOfDerivatives=maxNumberOfDerivatives
              DO derivativeIdx=1,numberOfDerivatives
                CALL MeshTopology_NodeDerivativeInitialise(nodes%nodes(nodeIdx)%derivatives(derivativeIdx),err,error,*999)
                nodes%nodes(nodeIdx)%derivatives(derivativeIdx)%partialDerivativeIndex = derivatives(derivativeIdx)
                globalDerivative=PARTIAL_DERIVATIVE_GLOBAL_DERIVATIVE_MAP(derivatives(derivativeIdx))
                IF(globalDerivative/=0) THEN
                  nodes%nodes(nodeIdx)%derivatives(derivativeIdx)%globalDerivativeIndex=globalDerivative
                ELSE
                  localError="The partial derivative index of "//TRIM(NumberToVstring(derivatives(derivativeIdx),"*", &
                    & err,error))//" for derivative number "//TRIM(NumberToVstring(derivativeIdx,"*",err,error))// &
                    & " does not have a corresponding global derivative."
                  CALL FlagError(localError,err,error,*999)
                ENDIF
              ENDDO !derivativeIdx
              DEALLOCATE(derivatives)
            ELSE
              localError="Invalid mesh configuration. User node "// &
                & TRIM(NumberToVstring(nodes%nodes(nodeIdx)%userNumber,"*",err,error))// &
                & " has inconsistent derivative directions."
              CALL FlagError(localError,err,error,*999)
            ENDIF
          ENDDO !nodeIdx
        ELSE
          CALL FlagError("Mesh topology nodes is not associated.",err,error,*999)
        ENDIF
      ELSE
        CALL FlagError("Mesh topology elements is not associated.",err,error,*999)
      ENDIF
    ELSE
      CALL FlagError("Mesh topology is not associated.",err,error,*999)
    ENDIF

    IF(diagnostics1) THEN
      CALL WriteStringValue(DIAGNOSTIC_OUTPUT_TYPE,"Number of mesh global nodes = ",nodes%numberOfNodes,err,error,*999)
      DO nodeIdx=1,nodes%numberOfNodes
        CALL WriteStringValue(DIAGNOSTIC_OUTPUT_TYPE,"  Mesh global node number = ",nodeIdx,err,error,*999)
        CALL WriteStringValue(DIAGNOSTIC_OUTPUT_TYPE,"    Number of derivatives = ",nodes%nodes(nodeIdx)%numberOfDerivatives, &
          & err,error,*999)
        DO derivativeIdx=1,nodes%nodes(nodeIdx)%numberOfDerivatives
          !TODO: change output string below so that it writes out derivativeIdx index as well
          CALL WriteStringValue(DIAGNOSTIC_OUTPUT_TYPE,"    Global derivative index(derivativeIdx) = ", &
            & nodes%nodes(nodeIdx)%derivatives(derivativeIdx)%globalDerivativeIndex,err,error,*999)
          CALL WriteStringValue(DIAGNOSTIC_OUTPUT_TYPE,"    Partial derivative index(derivativeIdx) = ", &
            & nodes%nodes(nodeIdx)%derivatives(derivativeIdx)%partialDerivativeIndex,err,error,*999)
        ENDDO !derivativeIdx
      ENDDO !node_idx
    ENDIF

    EXITS("MeshTopology_NodesDerivativesCalculate")
    RETURN
999 IF(ALLOCATED(derivatives)) DEALLOCATE(derivatives)
    IF(ASSOCIATED(nodeDerivativeList)) CALL LIST_DESTROY(nodeDerivativeList,err,error,*998)
998 ERRORSEXITS("MeshTopology_NodesDerivativesCalculate",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_NodesDerivativesCalculate

  !
  !================================================================================================================================
  !

  !>Returns the number of derivatives for a node in a mesh
  SUBROUTINE MeshTopology_NodeNumberOfDerivativesGet(meshNodes,userNumber,numberOfDerivatives,err,error,*)

    !Argument variables
    TYPE(MeshNodesType), POINTER :: meshNodes !<A pointer to the mesh nodes containing the nodes to get the number of derivatives for
    INTEGER(INTG), INTENT(IN) :: userNumber !<The user node number to get the number of derivatives for
    INTEGER(INTG), INTENT(OUT) :: numberOfDerivatives !<On return, the number of global derivatives at the specified user node number.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: meshComponentNumber,meshNumber
    LOGICAL :: nodeExists
    TYPE(MESH_TYPE), POINTER :: mesh
    TYPE(MeshComponentTopologyType), POINTER :: meshComponentTopology
    TYPE(VARYING_STRING) :: localError

    ENTERS("MeshTopology_NodeNumberOfDerivativesGet",err,error,*999)

    IF(ASSOCIATED(meshNodes)) THEN
      CALL MeshTopology_NodeCheckExists(meshNodes,userNumber,nodeExists,meshNumber,err,error,*999)
      IF(nodeExists) THEN
        numberOfDerivatives=meshNodes%nodes(meshNumber)%numberOfDerivatives
      ELSE
        meshComponentTopology=>meshNodes%meshComponentTopology
        IF(ASSOCIATED(meshComponentTopology)) THEN
          mesh=>meshComponentTopology%mesh
          IF(ASSOCIATED(mesh)) THEN
            meshComponentNumber=meshComponentTopology%meshComponentNumber
            localError="The user node number "//TRIM(NumberToVString(userNumber,"*",err,error))// &
              & " does not exist in mesh component number "//TRIM(NumberToVString(meshComponentNumber,"*",err,error))// &
              & " of mesh number "//TRIM(NumberToVString(mesh%USER_NUMBER,"*",err,error))//"."
            CALL FlagError(localError,err,error,*999)
          ELSE
            CALL FlagError("Mesh component topology mesh is not associated.",err,error,*999)
          ENDIF
        ELSE
          CALL FlagError("Mesh nodes mesh component topology is not associated.",err,error,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Mesh nodes is not associated.",err,error,*999)
    ENDIF

    EXITS("MeshTopology_NodeNumberOfDerivativesGet")
    RETURN
999 ERRORSEXITS("MeshTopology_NodeNumberOfDerivativesGet",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_NodeNumberOfDerivativesGet

  !
  !================================================================================================================================
  !

  !>Returns the global derivative numbers for a node in mesh nodes
  SUBROUTINE MeshTopology_NodeDerivativesGet(meshNodes,userNumber,derivatives,err,error,*)

    !Argument variables
    TYPE(MeshNodesType), POINTER :: meshNodes !<A pointer to the mesh nodes containing the node to get the derivatives for
    INTEGER(INTG), INTENT(IN) :: userNumber !<The user number of the node to get the derivatives for
    INTEGER(INTG), INTENT(OUT) :: derivatives(:) !<On return, the global derivatives at the specified node
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: derivativeIdx,meshComponentNumber,meshNumber,numberOfDerivatives
    LOGICAL :: nodeExists
    TYPE(MESH_TYPE), POINTER :: mesh
    TYPE(MeshComponentTopologyType), POINTER :: meshComponentTopology
    TYPE(VARYING_STRING) :: localError

    ENTERS("MeshTopology_NodeDerivativesGet",err,error,*999)

    IF(ASSOCIATED(meshNodes)) THEN
      CALL MeshTopology_NodeCheckExists(meshNodes,userNumber,nodeExists,meshNumber,err,error,*999)
      IF(nodeExists) THEN
        numberOfDerivatives=meshNodes%nodes(meshNumber)%numberOfDerivatives
        IF(SIZE(derivatives,1)>=numberOfDerivatives) THEN
          DO derivativeIdx=1,numberOfDerivatives
            derivatives(derivativeIdx)=meshNodes%nodes(meshNumber)%derivatives(derivativeIdx)%globalDerivativeIndex
          ENDDO !derivativeIdx
        ELSE
          localError="The size of the supplied derivatives array of "// &
            & TRIM(NumberToVString(SIZE(derivatives,1),"*",err,error))// &
            & " is too small. The size should be >= "// &
            & TRIM(NumberToVString(numberOfDerivatives,"*",err,error))//"."
          CALL FlagError(localError,err,error,*999)
        ENDIF
      ELSE
        meshComponentTopology=>meshNodes%meshComponentTopology
        IF(ASSOCIATED(meshComponentTopology)) THEN
          mesh=>meshComponentTopology%mesh
          IF(ASSOCIATED(mesh)) THEN
            meshComponentNumber=meshComponentTopology%meshComponentNumber
            localError="The user node number "//TRIM(NumberToVString(userNumber,"*",err,error))// &
              & " does not exist in mesh component number "//TRIM(NumberToVString(meshComponentNumber,"*",err,error))// &
              & " of mesh number "//TRIM(NumberToVString(mesh%USER_NUMBER,"*",err,error))//"."
            CALL FlagError(localError,err,error,*999)
          ELSE
            CALL FlagError("Mesh component topology mesh is not associated.",err,error,*999)
          ENDIF
        ELSE
          CALL FlagError("Mesh nodes mesh component topology is not associated.",err,error,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Mesh nodes is not associated.",err,error,*999)
    ENDIF

    EXITS("MeshTopology_NodeDerivativesGet")
    RETURN
999 ERRORSEXITS("MeshTopology_NodeDerivativesGet",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_NodeDerivativesGet

  !
  !================================================================================================================================
  !

  !>Returns the number of versions for a derivative of a node in mesh nodes
  SUBROUTINE MeshTopology_NodeNumberOfVersionsGet(meshNodes,derivativeNumber,userNumber,numberOfVersions,err,error,*)

    !Argument variables
    TYPE(MeshNodesType), POINTER :: meshNodes !<A pointer to the mesh nodes containing the node to get the number of versions for
    INTEGER(INTG), INTENT(IN) :: derivativeNumber !<The derivative number of the node to get the number of versions for
    INTEGER(INTG), INTENT(IN) :: userNumber !<The user number of the node to get the number of versions for
    INTEGER(INTG), INTENT(OUT) :: numberOfVersions !<On return, the number of versions for the specified derivative of the specified node
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: meshComponentNumber,meshNumber
    LOGICAL :: nodeExists
    TYPE(MESH_TYPE), POINTER :: mesh
    TYPE(MeshComponentTopologyType), POINTER :: meshComponentTopology
    TYPE(VARYING_STRING) :: localError

    ENTERS("MeshTopology_NodeNumberOfVersionsGet",err,error,*999)

    IF(ASSOCIATED(meshNodes)) THEN
      CALL MeshTopology_NodeCheckExists(meshNodes,userNumber,nodeExists,meshNumber,err,error,*999)
      IF(nodeExists) THEN
        IF(derivativeNumber>=1.AND.derivativeNumber<=meshNodes%nodes(meshNumber)%numberOfDerivatives) THEN
          numberOfVersions=meshNodes%nodes(meshNumber)%derivatives(derivativeNumber)%numberOfVersions
        ELSE
          localError="The specified derivative index of "// &
            & TRIM(NumberToVString(derivativeNumber,"*",err,error))// &
            & " is invalid. The derivative index must be >= 1 and <= "// &
            & TRIM(NumberToVString(meshNodes%nodes(meshNumber)%numberOfDerivatives,"*",err,error))// &
            & " for user node number "//TRIM(NumberToVString(userNumber,"*",err,error))//"."
          CALL FlagError(localError,err,error,*999)
        ENDIF
      ELSE
        meshComponentTopology=>meshNodes%meshComponentTopology
        IF(ASSOCIATED(meshComponentTopology)) THEN
          mesh=>meshComponentTopology%mesh
          IF(ASSOCIATED(mesh)) THEN
            meshComponentNumber=meshComponentTopology%meshComponentNumber
            localError="The user node number "//TRIM(NumberToVString(userNumber,"*",err,error))// &
              & " does not exist in mesh component number "//TRIM(NumberToVString(meshComponentNumber,"*",err,error))// &
              & " of mesh number "//TRIM(NumberToVString(mesh%USER_NUMBER,"*",err,error))//"."
            CALL FlagError(localError,err,error,*999)
          ELSE
            CALL FlagError("Mesh component topology mesh is not associated.",err,error,*999)
          ENDIF
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Mesh nodes is not associated.",err,error,*999)
    ENDIF

    EXITS("MeshTopology_NodeNumberOfVersionsGet")
    RETURN
999 ERRORSEXITS("MeshTopology_NodeNumberOfVersionsGet",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_NodeNumberOfVersionsGet

  !
  !================================================================================================================================
  !

  !>Returns the number of nodes for a node in a mesh
  SUBROUTINE MeshTopology_NodesNumberOfNodesGet(meshNodes,numberOfNodes,err,error,*)

    !Argument variables
    TYPE(MeshNodesType), POINTER :: meshNodes !<A pointer to the mesh nodes containing the nodes to get the number of nodes for
    INTEGER(INTG), INTENT(OUT) :: numberOfNodes !<On return, the number of nodes in the mesh.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables

    ENTERS("MeshTopology_NodesNumberOfNodesGet",err,error,*999)

    IF(ASSOCIATED(meshNodes)) THEN
      numberOfNodes=meshNodes%numberOfNodes
    ELSE
      CALL FlagError("Mesh nodes is not associated.",err,error,*999)
    ENDIF

    EXITS("MeshTopology_NodesNumberOfNodesGet")
    RETURN
999 ERRORSEXITS("MeshTopology_NodesNumberOfNodesGet",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_NodesNumberOfNodesGet

  !
  !================================================================================================================================
  !

  !>Calculates the number of versions at each node in a topology.
  SUBROUTINE MeshTopology_NodesVersionCalculate(topology,err,error,*)

    !Argument variables
    TYPE(MeshComponentTopologyType), POINTER :: topology !<A pointer to the mesh topology to calculate the versions at each node for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: element,localNodeIdx,derivativeIdx,nodeIdx,numberOfVersions,versionIdx
    INTEGER(INTG), ALLOCATABLE :: versions(:)
    TYPE(LIST_PTR_TYPE), POINTER :: nodeVersionList(:,:)
    TYPE(MeshElementsType), POINTER :: elements
    TYPE(MeshNodesType), POINTER :: nodes
    TYPE(BASIS_TYPE), POINTER :: basis

    ENTERS("MeshTopology_NodesVersionCalculate",err,error,*999)

    IF(ASSOCIATED(topology)) THEN
      elements=>topology%elements
      IF(ASSOCIATED(elements)) THEN
        nodes=>topology%nodes
        IF(ASSOCIATED(nodes)) THEN
          !Loop over the mesh elements
          !Calculate the number of versions at each node. This needs to be calculated by looking at all the mesh elements
          !as we may have an adjacent elements in another domain with a higher order basis along with different versions
          !being assigned to its derivatives.
          !\todo : See if there are any constraints that can be applied to restrict the amount of memory being allocated here
          ALLOCATE(nodeVersionList(MAXIMUM_GLOBAL_DERIV_NUMBER,nodes%numberOfNodes),STAT=err)
          IF(err/=0) CALL FlagError("Could not allocate node version list.",err,error,*999)
          DO nodeIdx=1,nodes%numberOfNodes
            DO derivativeIdx=1,nodes%nodes(nodeIdx)%numberOfDerivatives
              NULLIFY(nodeVersionList(derivativeIdx,nodeIdx)%ptr)
              CALL LIST_CREATE_START(nodeVersionList(derivativeIdx,nodeIdx)%ptr,err,error,*999)
              CALL LIST_DATA_TYPE_SET(nodeVersionList(derivativeIdx,nodeIdx)%ptr,LIST_INTG_TYPE,err,error,*999)
              CALL LIST_INITIAL_SIZE_SET(nodeVersionList(derivativeIdx,nodeIdx)%ptr,8,err,error,*999)
              CALL LIST_CREATE_FINISH(nodeVersionList(derivativeIdx,nodeIdx)%ptr,err,error,*999)
            ENDDO!derivativeIdx
          ENDDO!nodeIdx
          DO element=1,elements%NUMBER_OF_ELEMENTS
            basis=>elements%elements(element)%basis
            DO localNodeIdx=1,BASIS%NUMBER_OF_NODES
              DO derivativeIdx=1,basis%NUMBER_OF_DERIVATIVES(localNodeIdx)
                CALL LIST_ITEM_ADD(nodeVersionList(derivativeIdx,elements%elements(element)% &
                  & MESH_ELEMENT_NODES(localNodeIdx))%ptr,elements%elements(element)%USER_ELEMENT_NODE_VERSIONS( &
                  & derivativeIdx,localNodeIdx),err,error,*999)
              ENDDO!derivativeIdx
            ENDDO!localNodeIdx
          ENDDO!element
          DO nodeIdx=1,nodes%numberOfNodes
            DO derivativeIdx=1,nodes%nodes(nodeIdx)%numberOfDerivatives
              CALL LIST_REMOVE_DUPLICATES(nodeVersionList(derivativeIdx,nodeIdx)%ptr,err,error,*999)
              CALL LIST_DETACH_AND_DESTROY(nodeVersionList(derivativeIdx,nodeIdx)%ptr,numberOfVersions,versions, &
                & err,error,*999)
              nodes%nodes(nodeIdx)%derivatives(derivativeIdx)%numberOfVersions = MAXVAL(versions(1:numberOfVersions))
              ALLOCATE(nodes%nodes(nodeIdx)%derivatives(derivativeIdx)%userVersionNumbers(nodes%nodes(nodeIdx)% &
                & derivatives(derivativeIdx)%numberOfVersions),STAT=err)
              IF(err/=0) CALL FlagError("Could not allocate node global derivative index.",err,error,*999)
              DO versionIdx=1,nodes%nodes(nodeIdx)%derivatives(derivativeIdx)%numberOfVersions
                nodes%nodes(nodeIdx)%derivatives(derivativeIdx)%userVersionNumbers(versionIdx) = versionIdx
              ENDDO !versionIdx
              DEALLOCATE(versions)
            ENDDO!derivativeIdx
          ENDDO!nodeIdx
          DEALLOCATE(nodeVersionList)
          NULLIFY(nodeVersionList)
        ELSE
          CALL FlagError("Mesh topology nodes is not associated.",err,error,*999)
        ENDIF
      ELSE
        CALL FlagError("Mesh topology elements is not associated.",err,error,*999)
      ENDIF
    ELSE
      CALL FlagError("Mesh topology is not associated.",err,error,*999)
    ENDIF

    IF(diagnostics1) THEN
      CALL WriteStringValue(DIAGNOSTIC_OUTPUT_TYPE,"Number of mesh global nodes = ",nodes%numberOfNodes,err,error,*999)
      DO nodeIdx=1,nodes%numberOfNodes
        CALL WriteStringValue(DIAGNOSTIC_OUTPUT_TYPE,"  Mesh global node number = ",nodeIdx,err,error,*999)
        CALL WriteStringValue(DIAGNOSTIC_OUTPUT_TYPE,"    Number of derivatives = ", &
          & nodes%nodes(nodeIdx)%numberOfDerivatives,err,error,*999)
        DO derivativeIdx=1,nodes%nodes(nodeIdx)%numberOfDerivatives
          !\todo : change output string below so that it writes out derivativeIdx index as well
          CALL WriteStringValue(DIAGNOSTIC_OUTPUT_TYPE,"    Global derivative index(derivativeIdx) = ", &
            & nodes%nodes(nodeIdx)%derivatives(derivativeIdx)%globalDerivativeIndex,err,error,*999)
          CALL WriteStringValue(DIAGNOSTIC_OUTPUT_TYPE,"    Partial derivative index(derivativeIdx) = ", &
            & nodes%nodes(nodeIdx)%derivatives(derivativeIdx)%partialDerivativeIndex,err,error,*999)
          CALL WRITE_STRING_VECTOR(DIAGNOSTIC_OUTPUT_TYPE,1,1, &
            & nodes%nodes(nodeIdx)%derivatives(derivativeIdx)%numberOfVersions,8,8, &
            & nodes%nodes(nodeIdx)%derivatives(derivativeIdx)%userVersionNumbers, &
            & '("    User Version index(derivativeIdx,:) :",8(X,I2))','(36X,8(X,I2))',err,error,*999)
        ENDDO!derivativeIdx
      ENDDO !nodeIdx
    ENDIF

    EXITS("MeshTopology_NodesVersionCalculate")
    RETURN
999 IF(ALLOCATED(versions)) DEALLOCATE(versions)
    IF(ASSOCIATED(nodeVersionList)) THEN
      DO nodeIdx=1,nodes%numberOfNodes
        DO derivativeIdx=1,nodes%nodes(nodeIdx)%numberOfDerivatives
          CALL LIST_DESTROY(nodeVersionList(derivativeIdx,nodeIdx)%ptr,err,error,*998)
        ENDDO !derivativeIdx
      ENDDO !nodeIdx
      DEALLOCATE(nodeVersionList)
    ENDIF
998 ERRORSEXITS("MeshTopology_NodesVersionCalculate",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_NodesVersionCalculate

  !
  !================================================================================================================================
  !

  !>Returns if the node in a mesh is on the boundary or not
  SUBROUTINE MeshTopology_NodeOnBoundaryGet(meshNodes,userNumber,onBoundary,err,error,*)

    !Argument variables
    TYPE(MeshNodesType), POINTER :: meshNodes !<A pointer to the mesh nodes containing the nodes to get the boundary type for
    INTEGER(INTG), INTENT(IN) :: userNumber !<The user node number to get the boundary type for
    INTEGER(INTG), INTENT(OUT) :: onBoundary !<On return, the boundary type of the specified user node number.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: meshNumber

    ENTERS("MeshTopology_NodeOnBoundaryGet",err,error,*999)

    IF(.NOT.ASSOCIATED(meshNodes)) CALL FlagError("Mesh nodes is not associated.",err,error,*999)
    IF(.NOT.ALLOCATED(meshNodes%nodes)) CALL FlagError("Mesh nodes nodes is not allocated.",err,error,*999)

    CALL MeshTopology_NodeGet(meshNodes,userNumber,meshNumber,err,error,*999)
    IF(meshNodes%nodes(meshNumber)%boundaryNode) THEN
      onBoundary=MESH_ON_DOMAIN_BOUNDARY
    ELSE
      onBoundary=MESH_OFF_DOMAIN_BOUNDARY
    ENDIF

    EXITS("MeshTopology_NodeOnBoundaryGet")
    RETURN
999 ERRORSEXITS("MeshTopology_NodeOnBoundaryGet",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_NodeOnBoundaryGet

  !
  !================================================================================================================================
  !

  !>Calculates the element numbers surrounding a node for a mesh.
  SUBROUTINE MeshTopology_SurroundingElementsCalculate(topology,err,error,*)

    !Argument variables
    TYPE(MeshComponentTopologyType), POINTER :: topology !<A pointer to the mesh topology to calculate the elements surrounding each node for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: element,elementIdx,insertPosition,localNodeIdx,node,surroundingElementNumber
    INTEGER(INTG), POINTER :: newSurroundingElements(:)
    LOGICAL :: foundElement
    TYPE(BASIS_TYPE), POINTER :: basis
    TYPE(MeshElementsType), POINTER :: elements
    TYPE(MeshNodesType), POINTER :: nodes

    NULLIFY(newSurroundingElements)

    ENTERS("MeshTopology_SurroundingElementsCalculate",err,error,*999)

    IF(ASSOCIATED(topology)) THEN
      elements=>topology%elements
      IF(ASSOCIATED(elements)) THEN
        nodes=>topology%nodes
        IF(ASSOCIATED(nodes)) THEN
          IF(ALLOCATED(nodes%nodes)) THEN
            DO elementIdx=1,elements%NUMBER_OF_ELEMENTS
              basis=>elements%elements(elementIdx)%basis
              DO localNodeIdx=1,basis%NUMBER_OF_NODES
                node=elements%elements(elementIdx)%MESH_ELEMENT_NODES(localNodeIdx)
                foundElement=.FALSE.
                element=1
                insertPosition=1
                DO WHILE(element<=nodes%nodes(node)%numberOfSurroundingElements.AND..NOT.foundElement)
                  surroundingElementNumber=nodes%nodes(node)%surroundingElements(element)
                  IF(surroundingElementNumber==elementIdx) THEN
                    foundElement=.TRUE.
                  ENDIF
                  element=element+1
                  IF(elementIdx>=surroundingElementNumber) THEN
                    insertPosition=element
                  ENDIF
                ENDDO
                IF(.NOT.foundElement) THEN
                  !Insert element into surrounding elements
                  ALLOCATE(newSurroundingElements(nodes%nodes(node)%numberOfSurroundingElements+1),STAT=err)
                  IF(err/=0) CALL FlagError("Could not allocate new surrounding elements.",err,error,*999)
                  IF(ASSOCIATED(nodes%nodes(node)%surroundingElements)) THEN
                    newSurroundingElements(1:insertPosition-1)=nodes%nodes(node)%surroundingElements(1:insertPosition-1)
                    newSurroundingElements(insertPosition)=elementIdx
                    newSurroundingElements(insertPosition+1:nodes%nodes(node)%numberOfSurroundingElements+1)= &
                      & nodes%nodes(node)%surroundingElements(insertPosition:nodes%nodes(node)%numberOfSurroundingElements)
                    DEALLOCATE(nodes%nodes(node)%surroundingElements)
                  ELSE
                    newSurroundingElements(1)=elementIdx
                  ENDIF
                  nodes%nodes(node)%surroundingElements=>newSurroundingElements
                  nodes%nodes(node)%numberOfSurroundingElements=nodes%nodes(node)%numberOfSurroundingElements+1
                ENDIF
              ENDDO !localNodeIdx
            ENDDO !elementIdx
          ELSE
            CALL FlagError("Mesh topology nodes nodes have not been allocated.",err,error,*999)
          ENDIF
        ELSE
          CALL FlagError("Mesh topology nodes are not associated.",err,error,*999)
        ENDIF
      ELSE
        CALL FlagError("Mesh topology elements is not associated.",err,error,*999)
      ENDIF
    ELSE
      CALL FlagError("Mesh topology not associated.",err,error,*999)
    ENDIF

    EXITS("MeshTopology_SurroundingElementsCalculate")
    RETURN
999 IF(ASSOCIATED(newSurroundingElements)) DEALLOCATE(newSurroundingElements)
    ERRORSEXITS("MeshTopology_SurroundingElementsCalculate",err,error)
    RETURN 1
  END SUBROUTINE MeshTopology_SurroundingElementsCalculate

  !
  !===============================================================================================================================
  !

  !>Finalises the nodes data structures for a mesh topology and deallocates any memory.
  SUBROUTINE MeshTopology_NodesFinalise(nodes,err,error,*)

    !Argument variables
    TYPE(MeshNodesType), POINTER :: nodes !<A pointer to the mesh topology nodes to finalise the nodes for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: nodeIdx

    ENTERS("MeshTopology_NodesFinalise",err,error,*999)

    IF(ASSOCIATED(nodes)) THEN
      IF(ALLOCATED(nodes%nodes)) THEN
        DO nodeIdx=1,SIZE(nodes%nodes,1)
          CALL MeshTopology_NodeFinalise(nodes%nodes(nodeIdx),err,error,*999)
        ENDDO !nodesIdx
        DEALLOCATE(nodes%nodes)
      ENDIF
      IF(ASSOCIATED(nodes%nodesTree)) CALL TREE_DESTROY(nodes%nodesTree,err,error,*999)
      DEALLOCATE(nodes)
    ENDIF

    EXITS("MeshTopology_NodesFinalise")
    RETURN
999 ERRORSEXITS("MeshTopology_NodesFinalise",err,error)
    RETURN 1

  END SUBROUTINE MeshTopology_NodesFinalise

  !
  !================================================================================================================================
  !

  !>Initialises the nodes in a given mesh topology. \todo finalise on errors
  SUBROUTINE MeshTopology_NodesInitialise(topology,err,error,*)

    !Argument variables
    TYPE(MeshComponentTopologyType), POINTER :: topology !<A pointer to the mesh topology to initialise the nodes for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables

    ENTERS("MeshTopology_NodesInitialise",err,error,*999)

    IF(ASSOCIATED(topology)) THEN
      IF(ASSOCIATED(topology%nodes)) THEN
        CALL FlagError("Mesh already has topology nodes associated.",err,error,*999)
      ELSE
        ALLOCATE(topology%nodes,STAT=err)
        IF(err/=0) CALL FlagError("Could not allocate topology nodes.",err,error,*999)
        topology%nodes%numberOfNodes=0
        topology%nodes%meshComponentTopology=>topology
        NULLIFY(topology%nodes%nodesTree)
      ENDIF
    ELSE
      CALL FlagError("Topology is not associated.",err,error,*999)
    ENDIF

    EXITS("MeshTopology_NodesInitialise")
    RETURN
999 ERRORSEXITS("MeshTopology_NodesInitialise",err,error)
    RETURN 1
  END SUBROUTINE MeshTopology_NodesInitialise

  !
  !================================================================================================================================
  !

  !>Finalises the meshes and deallocates all memory
  SUBROUTINE MESHES_FINALISE(MESHES,ERR,ERROR,*)

   !Argument variables
    TYPE(MESHES_TYPE), POINTER :: MESHES !<A pointer to the meshes to finalise the meshes for.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(MESH_TYPE), POINTER :: MESH

    ENTERS("MESHES_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(MESHES)) THEN
      DO WHILE(MESHES%NUMBER_OF_MESHES>0)
        MESH=>MESHES%MESHES(1)%PTR
        CALL MESH_DESTROY(MESH,ERR,ERROR,*999)
      ENDDO !mesh_idx
      DEALLOCATE(MESHES)
    ELSE
      CALL FlagError("Meshes is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("MESHES_FINALISE")
    RETURN
999 ERRORSEXITS("MESHES_FINALISE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE MESHES_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the generic meshes.
  SUBROUTINE MESHES_INITIALISE_GENERIC(MESHES,ERR,ERROR,*)

    !Argument variables
    TYPE(MESHES_TYPE), POINTER :: MESHES !<A pointer to the meshes to initialise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR

    ENTERS("MESHES_INITIALISE_GENERIC",ERR,ERROR,*998)

    IF(ASSOCIATED(MESHES)) THEN
      CALL FlagError("Meshes is already associated.",ERR,ERROR,*998)
    ELSE
      ALLOCATE(MESHES,STAT=ERR)
      IF(ERR/=0) CALL FlagError("Meshes could not be allocated",ERR,ERROR,*999)
      NULLIFY(MESHES%REGION)
      NULLIFY(MESHES%INTERFACE)
      MESHES%NUMBER_OF_MESHES=0
      NULLIFY(MESHES%MESHES)
    ENDIF

    EXITS("MESHES_INITIALISE_GENERIC")
    RETURN
999 CALL MESHES_FINALISE(MESHES,DUMMY_ERR,DUMMY_ERROR,*998)
998 ERRORSEXITS("MESHES_INITIALISE_GENERIC",ERR,ERROR)
    RETURN 1
  END SUBROUTINE MESHES_INITIALISE_GENERIC

  !
  !================================================================================================================================
  !

  !>Initialises the meshes for the given interface.
  SUBROUTINE MESHES_INITIALISE_INTERFACE(INTERFACE,ERR,ERROR,*)

    !Argument variables
    TYPE(INTERFACE_TYPE), POINTER :: INTERFACE !<A pointer to the interface to initialise the meshes for.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("MESHES_INITIALISE_INTERFACE",ERR,ERROR,*999)

    IF(ASSOCIATED(INTERFACE)) THEN
      IF(ASSOCIATED(INTERFACE%MESHES)) THEN
        LOCAL_ERROR="Interface number "//TRIM(NumberToVString(INTERFACE%USER_NUMBER,"*",ERR,ERROR))// &
          & " already has a mesh associated"
        CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
      ELSE
        CALL MESHES_INITIALISE_GENERIC(INTERFACE%MESHES,ERR,ERROR,*999)
        INTERFACE%MESHES%INTERFACE=>INTERFACE
      ENDIF
    ELSE
      CALL FlagError("Interface is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("MESHES_INITIALISE_INTERFACE")
    RETURN
999 ERRORSEXITS("MESHES_INITIALISE_INTERFACE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE MESHES_INITIALISE_INTERFACE

  !
  !================================================================================================================================
  !

  !>Initialises the meshes for the given region.
  SUBROUTINE MESHES_INITIALISE_REGION(REGION,ERR,ERROR,*)

    !Argument variables
    TYPE(REGION_TYPE), POINTER :: REGION !<A pointer to the region to initialise the meshes for.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("MESHES_INITIALISE_REGION",ERR,ERROR,*999)

    IF(ASSOCIATED(REGION)) THEN
      IF(ASSOCIATED(REGION%MESHES)) THEN
        LOCAL_ERROR="Region number "//TRIM(NumberToVString(REGION%USER_NUMBER,"*",ERR,ERROR))// &
          & " already has a mesh associated"
        CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
      ELSE
        CALL MESHES_INITIALISE_GENERIC(REGION%MESHES,ERR,ERROR,*999)
        REGION%MESHES%REGION=>REGION
      ENDIF
    ELSE
      CALL FlagError("Region is not associated",ERR,ERROR,*999)
    ENDIF

    EXITS("MESHES_INITIALISE_REGION")
    RETURN
999 ERRORSEXITS("MESHES_INITIALISE_REGION",ERR,ERROR)
    RETURN 1
  END SUBROUTINE MESHES_INITIALISE_REGION

  !
  !================================================================================================================================
  !

  !>Gets the domain for a given node in a decomposition of a mesh. \todo should be able to specify lists of elements. \see OPENCMISS::Iron::cmfe_DecompositionNodeDomainGet
  SUBROUTINE DECOMPOSITION_NODE_DOMAIN_GET(DECOMPOSITION,USER_NODE_NUMBER,MESH_COMPONENT_NUMBER,DOMAIN_NUMBER,ERR,ERROR,*)

    !Argument variables
    TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION !<A pointer to the decomposition to set the element domain for
    INTEGER(INTG), INTENT(IN) :: USER_NODE_NUMBER !<The global element number to set the domain for.
    INTEGER(INTG), INTENT(IN) :: MESH_COMPONENT_NUMBER !<The mesh component number to set the domain for.
    INTEGER(INTG), INTENT(OUT) :: DOMAIN_NUMBER !<On return, the domain of the global element.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables`
    TYPE(MESH_TYPE), POINTER :: MESH
    TYPE(MeshComponentTopologyType), POINTER :: MESH_TOPOLOGY
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    INTEGER(INTG) :: GLOBAL_NODE_NUMBER
    TYPE(TREE_NODE_TYPE), POINTER :: TREE_NODE
    TYPE(MeshNodesType), POINTER :: MESH_NODES
    TYPE(DOMAIN_TYPE), POINTER :: MESH_DOMAIN

    ENTERS("DECOMPOSITION_NODE_DOMAIN_GET",ERR,ERROR,*999)

!!TODO: interface should specify user element number ???
    GLOBAL_NODE_NUMBER=0
    IF(ASSOCIATED(DECOMPOSITION)) THEN
      IF(DECOMPOSITION%DECOMPOSITION_FINISHED) THEN
        MESH=>DECOMPOSITION%MESH
        IF(ASSOCIATED(MESH)) THEN
          MESH_TOPOLOGY=>MESH%TOPOLOGY(MESH_COMPONENT_NUMBER)%PTR
          IF(ASSOCIATED(MESH_TOPOLOGY)) THEN
            MESH_NODES=>MESH_TOPOLOGY%nodes
            IF(ASSOCIATED(MESH_NODES)) THEN
              NULLIFY(TREE_NODE)
              CALL TREE_SEARCH(MESH_NODES%nodesTree,USER_NODE_NUMBER,TREE_NODE,ERR,ERROR,*999)
              IF(ASSOCIATED(TREE_NODE)) THEN
                CALL TREE_NODE_VALUE_GET(MESH_NODES%nodesTree,TREE_NODE,GLOBAL_NODE_NUMBER,ERR,ERROR,*999)
                IF(GLOBAL_NODE_NUMBER>0.AND.GLOBAL_NODE_NUMBER<=MESH_TOPOLOGY%NODES%numberOfNodes) THEN
                  IF(MESH_COMPONENT_NUMBER>0.AND.MESH_COMPONENT_NUMBER<=MESH%NUMBER_OF_COMPONENTS) THEN
                    MESH_DOMAIN=>DECOMPOSITION%DOMAIN(MESH_COMPONENT_NUMBER)%PTR
                    IF(ASSOCIATED(MESH_DOMAIN)) THEN
                      DOMAIN_NUMBER=MESH_DOMAIN%NODE_DOMAIN(GLOBAL_NODE_NUMBER)
                    ELSE
                      CALL FlagError("Decomposition domain is not associated.",ERR,ERROR,*999)
                    ENDIF
                  ELSE
                    LOCAL_ERROR="Mesh Component number "//TRIM(NumberToVString(MESH_COMPONENT_NUMBER,"*",ERR,ERROR))// &
                      & " is invalid. The limits are 1 to "// &
                      & TRIM(NumberToVString(MESH%NUMBER_OF_COMPONENTS,"*",ERR,ERROR))//"."
                    CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                  ENDIF
                ELSE
                  LOCAL_ERROR="Global element number found "//TRIM(NumberToVString(GLOBAL_NODE_NUMBER,"*",ERR,ERROR))// &
                    & " is invalid. The limits are 1 to "// &
                    & TRIM(NumberToVString(MESH_TOPOLOGY%NODES%numberOfNodes,"*",ERR,ERROR))//"."
                  CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                ENDIF
              ELSE
                LOCAL_ERROR="Decomposition mesh node corresponding to user node number "// &
                  & TRIM(NumberToVString(USER_NODE_NUMBER,"*",err,error))//" is not found."
                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FlagError("Decomposition mesh nodes are not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Decomposition mesh topology is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Decomposition mesh is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Decomposition has not been finished.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Decomposition is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("DECOMPOSITION_NODE_DOMAIN_GET")
    RETURN
999 ERRORSEXITS("DECOMPOSITION_NODE_DOMAIN_GET",ERR,ERROR)
    RETURN 1
  END SUBROUTINE DECOMPOSITION_NODE_DOMAIN_GET

  !
  !================================================================================================================================
  !

  !>Initialises the embedded meshes.
  SUBROUTINE EMBEDDED_MESH_INITIALISE(MESH_EMBEDDING,ERR,ERROR,*)

    !Argument variables
    !TYPE(MESH_EMBEDDING_TYPE), INTENT(INOUT) :: MESH_EMBEDDING !<Mesh embedding to initialise
    TYPE(MESH_EMBEDDING_TYPE), POINTER :: MESH_EMBEDDING !<Mesh embedding to initialise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("EMBEDDED_MESH_INITIALISE",ERR,ERROR,*998)

    ALLOCATE(MESH_EMBEDDING,STAT=ERR)
    NULLIFY(MESH_EMBEDDING%PARENT_MESH)
    NULLIFY(MESH_EMBEDDING%CHILD_MESH)

    EXITS("EMBEDDED_MESH_INITIALISE")
    RETURN
!999 CALL EMBEDDED_MESH_FINALISE(MESH_EMBEDDING,DUMMY_ERR,DUMMY_ERROR,*998)
998 ERRORSEXITS("EMBEDDED_MESH_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EMBEDDED_MESH_INITIALISE

  !
  !================================================================================================================================
  !

  !>Creates an embedding of one mesh in another
  SUBROUTINE MESH_EMBEDDING_CREATE(MESH_EMBEDDING, PARENT_MESH, CHILD_MESH,ERR,ERROR,*)
!    TYPE(MESH_EMBEDDING_TYPE), INTENT(INOUT) :: MESH_EMBEDDING !<Mesh embedding to create.
    TYPE(MESH_EMBEDDING_TYPE), POINTER :: MESH_EMBEDDING !<Mesh embedding to create.
    TYPE(MESH_TYPE), POINTER, INTENT(IN) :: PARENT_MESH !<The parent mesh
    TYPE(MESH_TYPE), POINTER, INTENT(IN) :: CHILD_MESH  !<The child mesh
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local variables
    INTEGER(INTG) :: NGP = 0, ne

    ENTERS("MESH_EMBEDDING_CREATE",ERR,ERROR,*999)

    WRITE(*,*) 'parent mesh', PARENT_MESH%NUMBER_OF_ELEMENTS
    WRITE(*,*) 'child mesh', child_MESH%NUMBER_OF_ELEMENTS
    CALL EMBEDDED_MESH_INITIALISE(MESH_EMBEDDING,ERR,ERROR,*999)

    DO ne=1,PARENT_MESH%NUMBER_OF_ELEMENTS
      NGP = MAX(NGP,PARENT_MESH%TOPOLOGY(1)%PTR%ELEMENTS%ELEMENTS(ne)%BASIS%QUADRATURE%&
        & QUADRATURE_SCHEME_MAP(BASIS_DEFAULT_QUADRATURE_SCHEME)%PTR%NUMBER_OF_GAUSS)
    ENDDO !ne

    MESH_EMBEDDING%PARENT_MESH => PARENT_MESH
    MESH_EMBEDDING%CHILD_MESH  => CHILD_MESH
    ALLOCATE(MESH_EMBEDDING%CHILD_NODE_XI_POSITION(PARENT_MESH%NUMBER_OF_ELEMENTS),STAT=ERR)
    IF(ERR/=0) CALL FlagError("Could not allocate child node positions.",ERR,ERROR,*999)
    ALLOCATE(MESH_EMBEDDING%GAUSS_POINT_XI_POSITION(NGP,PARENT_MESH%NUMBER_OF_ELEMENTS),STAT=ERR)
    IF(ERR/=0) CALL FlagError("Could not allocate gauss point positions.",ERR,ERROR,*999)

    EXITS("MESH_EMBEDDING_CREATE")
    RETURN

999 ERRORSEXITS("MESH_EMBEDDING_CREATE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE MESH_EMBEDDING_CREATE

  !
  !================================================================================================================================
  !

  !>Sets the positions of nodes in the child mesh for one element in the parent mesh
  SUBROUTINE MESH_EMBEDDING_SET_CHILD_NODE_POSITION(MESH_EMBEDDING, ELEMENT_NUMBER, NODE_NUMBERS, XI_COORDS,ERR,ERROR,*)
    TYPE(MESH_EMBEDDING_TYPE), INTENT(INOUT) :: MESH_EMBEDDING !<The mesh embedding object
    INTEGER(INTG), INTENT(IN) :: ELEMENT_NUMBER  !<Element number in the parent mesh
    INTEGER(INTG), INTENT(IN) :: NODE_NUMBERS(:) !<NODE_NUMBERS(node_idx) Node numbers in child mesh for the node_idx'th embedded node in the ELEMENT_NUMBER'th element of the parent mesh
    REAL(DP), INTENT(IN)      :: XI_COORDS(:,:)  !<XI_COORDS(:,node_idx) Xi coordinates of the node_idx'th embedded node in the ELEMENT_NUMBER'th

    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string

    ENTERS("MESH_EMBEDDING_SET_CHILD_NODE_POSITION",ERR,ERROR,*999)

    IF(ELEMENT_NUMBER<1 .OR. ELEMENT_NUMBER > MESH_EMBEDDING%PARENT_MESH%NUMBER_OF_ELEMENTS) THEN
      CALL FlagError("Element number out of range",ERR,ERROR,*999)
    ENDIF

    MESH_EMBEDDING%CHILD_NODE_XI_POSITION(ELEMENT_NUMBER)%NUMBER_OF_NODES = SIZE(NODE_NUMBERS)

    ALLOCATE(MESH_EMBEDDING%CHILD_NODE_XI_POSITION(ELEMENT_NUMBER)%NODE_NUMBERS(SIZE(NODE_NUMBERS)))
    MESH_EMBEDDING%CHILD_NODE_XI_POSITION(ELEMENT_NUMBER)%NODE_NUMBERS(1:SIZE(NODE_NUMBERS)) = NODE_NUMBERS(1:SIZE(NODE_NUMBERS))

    ALLOCATE(MESH_EMBEDDING%CHILD_NODE_XI_POSITION(ELEMENT_NUMBER)%XI_COORDS(SIZE(XI_COORDS,1),SIZE(XI_COORDS,2)))
    MESH_EMBEDDING%CHILD_NODE_XI_POSITION(ELEMENT_NUMBER)%XI_COORDS(1:SIZE(XI_COORDS,1),1:SIZE(XI_COORDS,2)) = &
      & XI_COORDS(1:SIZE(XI_COORDS,1),1:SIZE(XI_COORDS,2))

    EXITS("MESH_EMBEDDING_SET_CHILD_NODE_POSITION")
    RETURN
999 ERRORSEXITS("MESH_EMBEDDING_SET_CHILD_NODE_POSITION",ERR,ERROR)
    RETURN 1
  END SUBROUTINE MESH_EMBEDDING_SET_CHILD_NODE_POSITION

  !
  !================================================================================================================================
  !

  !>Sets the positions of a Gauss point of the parent mesh in terms of element/xi coordinate in the child mesh
  SUBROUTINE MESH_EMBEDDING_SET_GAUSS_POINT_DATA(MESH_EMBEDDING, PARENT_ELEMENT_NUMBER, GAUSSPT_NUMBER,&
    & PARENT_XI_COORD, CHILD_ELEMENT_NUMBER, CHILD_XI_COORD,ERR,ERROR,*)
    TYPE(MESH_EMBEDDING_TYPE), INTENT(INOUT) :: MESH_EMBEDDING   !<The mesh embedding object
    INTEGER(INTG), INTENT(IN) :: PARENT_ELEMENT_NUMBER           !<Element number in the parent mesh
    INTEGER(INTG), INTENT(IN) :: GAUSSPT_NUMBER                  !<Gauss point number in this element
    REAL(DP), INTENT(IN) :: PARENT_XI_COORD(:)              !<Xi coordinate in parent element

    INTEGER(INTG), INTENT(IN) :: CHILD_ELEMENT_NUMBER !<Element number in the child mesh
    REAL(DP), INTENT(IN) :: CHILD_XI_COORD(:)    !<Xi coordinate in child element

    INTEGER(INTG), INTENT(OUT) :: ERR           !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR  !<The error string

    ENTERS("MESH_EMBEDDING_SET_GAUSS_POINT_DATA",ERR,ERROR,*999)

    IF(PARENT_ELEMENT_NUMBER<1 .OR. PARENT_ELEMENT_NUMBER > MESH_EMBEDDING%PARENT_MESH%NUMBER_OF_ELEMENTS) THEN
      CALL FlagError("Parent element number out of range",ERR,ERROR,*999)
    ENDIF
    IF(CHILD_ELEMENT_NUMBER<1 .OR. CHILD_ELEMENT_NUMBER > MESH_EMBEDDING%CHILD_MESH%NUMBER_OF_ELEMENTS) THEN
      CALL FlagError("Child element number out of range",ERR,ERROR,*999)
    ENDIF
    IF(GAUSSPT_NUMBER<1 .OR. GAUSSPT_NUMBER > SIZE(MESH_EMBEDDING%GAUSS_POINT_XI_POSITION,1)) THEN
      CALL FlagError("Gauss point number out of range",ERR,ERROR,*999)
    ENDIF

    ALLOCATE(MESH_EMBEDDING%GAUSS_POINT_XI_POSITION(GAUSSPT_NUMBER,PARENT_ELEMENT_NUMBER)&
     & %PARENT_XI_COORD(SIZE(PARENT_XI_COORD)))
    ALLOCATE(MESH_EMBEDDING%GAUSS_POINT_XI_POSITION(GAUSSPT_NUMBER,PARENT_ELEMENT_NUMBER)&
     & %CHILD_XI_COORD(SIZE(CHILD_XI_COORD)))


    MESH_EMBEDDING%GAUSS_POINT_XI_POSITION(GAUSSPT_NUMBER,PARENT_ELEMENT_NUMBER)%PARENT_XI_COORD(1:SIZE(PARENT_XI_COORD)) = &
      & PARENT_XI_COORD(1:SIZE(PARENT_XI_COORD))
    MESH_EMBEDDING%GAUSS_POINT_XI_POSITION(GAUSSPT_NUMBER,PARENT_ELEMENT_NUMBER)%CHILD_XI_COORD(1:SIZE(CHILD_XI_COORD)) = &
      & CHILD_XI_COORD(1:SIZE(CHILD_XI_COORD))
    MESH_EMBEDDING%GAUSS_POINT_XI_POSITION(GAUSSPT_NUMBER,PARENT_ELEMENT_NUMBER)%ELEMENT_NUMBER = CHILD_ELEMENT_NUMBER

    EXITS("MESH_EMBEDDING_SET_GAUSS_POINT_DATA")
    RETURN
999 ERRORSEXITS("MESH_EMBEDDING_SET_GAUSS_POINT_DATA",ERR,ERROR)
    RETURN 1
  END SUBROUTINE MESH_EMBEDDING_SET_GAUSS_POINT_DATA

  !
  !================================================================================================================================
  !

  !>Determines if a sorted integer array contains a particular element, if yes, returns the index where that element was found
  FUNCTION SORTED_ARRAY_CONTAINS_ELEMENT_INDEX(ARRAY,ELEMENT,FOUND_INDEX,ERR,ERROR)
    !Argument variables
    INTEGER(INTG), DIMENSION(:) :: ARRAY !<The array in which to search for the element, needs to be sorted
    INTEGER(INTG), INTENT(IN) :: ELEMENT !<The element to search for
    INTEGER(INTG), INTENT(OUT) :: FOUND_INDEX !< the search index of the array, where the element was found
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Function variable
    LOGICAL :: SORTED_ARRAY_CONTAINS_ELEMENT_INDEX
    !Local Variables
    !TYPE(VARYING_STRING) :: LOCAL_ERROR
    INTEGER(INTG) :: SearchIndex, ValueAtSearchIndex, LowerBoundSearchIndex, UpperBoundSearchIndex, &
      & PreviousSearchIndex

    ENTERS("SORTED_ARRAY_CONTAINS_ELEMENT_INDEX",ERR,ERROR,*999)

    SORTED_ARRAY_CONTAINS_ELEMENT_INDEX = .FALSE.

    IF (SIZE(ARRAY) == 0) RETURN

    SearchIndex = (LBOUND(ARRAY,1)+UBOUND(ARRAY,1))/2
    ! bound values are first indices where the elements can't be
    LowerBoundSearchIndex = LBOUND(ARRAY,1)-1
    UpperBoundSearchIndex = UBOUND(ARRAY,1)+1
    PreviousSearchIndex = -1

    !PRINT *, "find ",ELEMENT," in array: ",ARRAY,LBOUND(ARRAY,1),UBOUND(ARRAY,1)

    DO WHILE(LowerBoundSearchIndex < UpperBoundSearchIndex)
      ValueAtSearchIndex = ARRAY(SearchIndex)

      !PRINT *, "  [",LowerBoundSearchIndex,SearchIndex,UpperBoundSearchIndex,"]"
      !PRINT *, "  current pointer ValueAtSearchIndex=",ValueAtSearchIndex,", to search ELEMENT=", &
      !  & ELEMENT

      IF (ValueAtSearchIndex == ELEMENT) THEN
        ! global element number was found among local elements
        SORTED_ARRAY_CONTAINS_ELEMENT_INDEX = .TRUE.
        FOUND_INDEX = SearchIndex
        !PRINT *, "found"
        EXITS("SORTED_ARRAY_CONTAINS_ELEMENT_INDEX")
        RETURN

      ELSEIF (ValueAtSearchIndex > ELEMENT) THEN
        ! search position was too high
        UpperBoundSearchIndex = SearchIndex
        SearchIndex = NINT((SearchIndex+LowerBoundSearchIndex)/2.)

      ELSEIF (ValueAtSearchIndex < ELEMENT) THEN
        ! search position was too low
        LowerBoundSearchIndex = SearchIndex
        SearchIndex = NINT((SearchIndex+UpperBoundSearchIndex)/2.)
      ENDIF

      ! If search position did not change or new position is invalid, terminate search
      IF (SearchIndex == PreviousSearchIndex .OR. SearchIndex <= LBOUND(ARRAY,1)-1 .OR. SearchIndex >= UBOUND(ARRAY,1)+1) EXIT

      PreviousSearchIndex = SearchIndex
    ENDDO

    EXITS("SORTED_ARRAY_CONTAINS_ELEMENT_INDEX")
    RETURN
999 ERRORSEXITS("SORTED_ARRAY_CONTAINS_ELEMENT_INDEX",ERR,ERROR)
    RETURN
  END FUNCTION SORTED_ARRAY_CONTAINS_ELEMENT_INDEX

  !
  !================================================================================================================================
  !

  !>Determines if a sorted integer array contains a particular element
  FUNCTION SORTED_ARRAY_CONTAINS_ELEMENT(ARRAY,ELEMENT,ERR,ERROR)
    !Argument variables
    INTEGER(INTG), DIMENSION(:) :: ARRAY !<The array in which to search for the element, needs to be sorted
    INTEGER(INTG), INTENT(IN) :: ELEMENT !<The element to search for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Function variable
    LOGICAL :: SORTED_ARRAY_CONTAINS_ELEMENT
    !Local Variables
    !TYPE(VARYING_STRING) :: LOCAL_ERROR
    INTEGER(INTG) :: FoundIndex

    ENTERS("SORTED_ARRAY_CONTAINS_ELEMENT",ERR,ERROR,*999)

    SORTED_ARRAY_CONTAINS_ELEMENT = SORTED_ARRAY_CONTAINS_ELEMENT_INDEX(ARRAY,ELEMENT,FoundIndex,ERR,ERROR)

    EXITS("SORTED_ARRAY_CONTAINS_ELEMENT")
    RETURN
999 ERRORSEXITS("SORTED_ARRAY_CONTAINS_ELEMENT",ERR,ERROR)
    RETURN
  END FUNCTION SORTED_ARRAY_CONTAINS_ELEMENT

  !
  !================================================================================================================================
!

END MODULE MESH_ROUTINES
