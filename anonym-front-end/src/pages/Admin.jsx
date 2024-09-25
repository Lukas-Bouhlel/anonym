import React, { useState } from "react";
import { useUser } from '../context/UserContext';
import { Navigate } from "react-router-dom";

const Admin = () => {
    const { user } = useUser();

    return (
        <div id="admin">
           sfsfsfsffffs
        </div>
    )
}

export default Admin;