import { useForm } from "react-hook-form";

const Login = () => {
    const { register, handleSubmit, watch, formState: { errors }, } = useForm();
    const onSubmit = (data) => console.log(data);

    return ( 
        <div className="form-container sign-in">
            <form onSubmit={handleSubmit(onSubmit)}>
                <h1>Sign In</h1>
                <span>use your email password</span>
                <input type="email" placeholder="Email" {...register("email", { required: true })}/>
                <input type="password" placeholder="Password" {...register("password", { required: true })}/>
                <a href="#">Forget Your Password?</a>
                <button>Sign In</button>
            </form>
        </div>
    )
}
export default Login;