import { useForm } from 'react-hook-form';

const Register = () => {
    const { register, handleSubmit, watch, formState: { errors }, } = useForm();
    const onSubmit = (data) => console.log(data);

  return (
    <div className="form-container sign-up">
      <form onSubmit={handleSubmit(onSubmit)}>
        <h1>Create Account</h1>
        <span>use your email for registration</span>
        <input type="text" placeholder="Name" {...register("name", { required: true })}/>
        <input type="email" placeholder="Email" {...register("email", { required: true })}/>
        <input type="password" placeholder="Password" {...register("password", { required: true })}/>
        <button type="submit">Sign Up</button>
      </form>
    </div>
  );
};

export default Register;
